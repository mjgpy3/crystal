require_relative "program"
require_relative "transformer"

module Crystal
  class Program
    def normalize(node)
      return nil unless node
      normalizer = Normalizer.new(self)
      node = normalizer.normalize(node)
      puts node if ENV['SSA'] == '1'
      node
    end
  end

  class Normalizer < Transformer
    attr_reader :program

    def initialize(program)
      @program = program
      @vars = {}
      @vars_stack = []
    end

    def normalize(node)
      node.transform(self)
    end

    def before_transform(node)
      @dead_code = false
    end

    def after_transform(node)
      case node
      when Return, Break, Next
        @dead_code = true
      when If, Case, Unless, And, Or, Expressions
      else
        @dead_code = false
      end
    end

    def transform_expressions(node)
      exps = []
      node.expressions.each do |exp|
        new_exp = exp.transform(self)
        if new_exp
          if new_exp.is_a?(Expressions)
            exps.concat new_exp.expressions
          else
            exps << new_exp
          end
        end
        break if @dead_code
      end
      case exps.length
      when 0
        nil
      when 1
        exps[0]
      else
        node.expressions = exps
        node
      end
    end

    def transform_and(node)
      super

      if node.left.is_a?(Var) || (node.left.is_a?(IsA) && node.left.obj.is_a?(Var))
        If.new(node.left, node.right, node.left)
      else
        temp_var = new_temp_var
        If.new(Assign.new(temp_var, node.left), node.right, temp_var)
      end
    end

    def transform_or(node)
      super

      if node.left.is_a?(Var)
        If.new(node.left, node.left, node.right)
      else
        temp_var = new_temp_var
        If.new(Assign.new(temp_var, node.left), temp_var, node.right)
      end
    end

    def transform_require(node)
      required = program.require(node.string.value, node.filename)
      required ? required.transform(self) : nil
    end

    def transform_string_interpolation(node)
      super

      call = Call.new(Ident.new(["StringBuilder"], true), "new")
      node.expressions.each do |piece|
        call = Call.new(call, :<<, [piece])
      end
      Call.new(call, "to_s")
    end

    def transform_def(node)
      if node.has_default_arguments?
        exps = node.expand_default_arguments.map! { |a_def| a_def.transform(self) }
        return Expressions.new(exps)
      end

      if node.body
        pushing_vars(Hash[node.args.map { |arg| [arg.name, {read: 0, write: 1}] }]) do
          node.body = node.body.transform(self)
        end
      end

      node
    end

    def transform_macro(node)
      # if node.has_default_arguments?
      #   exps = node.expand_default_arguments.map! { |a_def| a_def.transform(self) }
      #   return Expressions.new(exps)
      # end

      if node.body
        pushing_vars(Hash[node.args.map { |arg| [arg.name, {read: 0, write: 1}] }]) do
          node.body = node.body.transform(self)
        end
      end

      node
    end

    def transform_unless(node)
      super

      If.new(node.cond, node.else, node.then)
    end

    def transform_case(node)
      node.cond = node.cond.transform(self)

      if node.cond.is_a?(Var) || node.cond.is_a?(InstanceVar)
        temp_var = node.cond
      else
        temp_var = new_temp_var
        assign = Assign.new(temp_var, node.cond)
      end

      a_if = nil
      final_if = nil
      node.whens.each do |wh|
        final_comp = nil
        wh.conds.each do |cond|
          right_side = temp_var

          comp = Call.new(cond, :'===', [right_side])
          if final_comp
            final_comp = SimpleOr.new(final_comp, comp)
          else
            final_comp = comp
          end
        end
        wh_if = If.new(final_comp, wh.body)
        if a_if
          a_if.else = wh_if
        else
          final_if = wh_if
        end
        a_if = wh_if
      end
      a_if.else = node.else if node.else
      final_if = final_if.transform(self)
      if assign
        Expressions.new([assign, final_if])
      else
        final_if
      end
    end

    def transform_range_literal(node)
      super

      Call.new(Ident.new(['Range'], true), 'new', [node.from, node.to, BoolLiteral.new(node.exclusive)])
    end

    def transform_regexp_literal(node)
      const_name = "#Regexp_#{node.value}"
      unless program.types[const_name]
        constructor = Call.new(Ident.new(['Regexp'], true), 'new', [StringLiteral.new(node.value)])
        program.types[const_name] = Const.new program, const_name, constructor, [program], program
      end

      Ident.new([const_name], true)
    end

    def transform_array_literal(node)
      super

      if node.of
        if node.elements.length == 0
          return Call.new(NewGenericClass.new(Ident.new(['Array'], true), [node.of]), 'new')
        end

        type_var = node.of
      else
        type_var = TypeMerge.new(node.elements)
      end

      length = node.elements.length
      capacity = length < 16 ? 16 : 2 ** Math.log(length, 2).ceil

      constructor = Call.new(NewGenericClass.new(Ident.new(['Array'], true), [type_var]), 'new', [IntLiteral.new(capacity)])
      temp_var = new_temp_var
      assign = Assign.new(temp_var, constructor)
      set_length = Call.new(temp_var, 'length=', [IntLiteral.new(length)])

      exps = [assign, set_length]

      node.elements.each_with_index do |elem, i|
        get_buffer = Call.new(temp_var, 'buffer')
        assign_index = Call.new(get_buffer, :[]=, [IntLiteral.new(i), elem])
        exps << assign_index
      end

      exps << temp_var

      Expressions.new(exps)
    end

    def transform_hash_literal(node)
      super

      if node.of_key
        type_vars = [node.of_key, node.of_value]
      else
        type_vars = [TypeMerge.new(node.keys), TypeMerge.new(node.values)]
      end

      constructor = Call.new(NewGenericClass.new(Ident.new(['Hash'], true), type_vars), 'new')
      if node.keys.length == 0
        constructor
      else
        temp_var = new_temp_var
        assign = Assign.new(temp_var, constructor)

        exps = [assign]
        node.keys.each_with_index do |key, i|
          exps << Call.new(temp_var, :[]=, [key, node.values[i]])
        end
        exps << temp_var
        Expressions.new exps
      end
    end

    def transform_assign(node)
      if node.target.is_a?(Var)
        node.value = node.value.transform(self)
        transform_assign_var(node.target)
      elsif node.target.is_a?(Ident)
        pushing_vars do
          node.value = node.value.transform(self)
        end
      else
        node.value = node.value.transform(self)
      end

      node
    end

    def transform_multi_assign(node)
      node.values.map! { |exp| exp.transform(self) }
      node.targets.each do |target|
        if target.is_a?(Var)
          transform_assign_var(target)
        end
      end

      node
    end

    def transform_assign_var(node)
      indices = @vars[node.name]
      if indices
        increment_var node.name, indices
        node.name = var_name_with_index(node.name, indices[:write])
      else
        @vars[node.name] = {read: 0, write: 1}
      end
    end

    def transform_if(node)
      node.cond = node.cond.transform(self)

      before_vars = @vars.clone
      then_vars = nil
      else_vars = nil

      if node.then
        node.then = node.then.transform(self)
        then_vars = @vars.clone
        then_dead_code = @dead_code
      end

      if node.else
        if then_vars
          before_else_vars = {}
          then_vars.each do |var_name, indices|
            before_indices = before_vars[var_name]
            read_index = before_indices ? before_indices[:read] : nil
            before_else_vars[var_name] = {read: read_index, write: indices[:write]}
          end
          pushing_vars(before_else_vars) do
            node.else = node.else.transform(self)
            else_vars = @vars.clone
          end
        else
          node.else = node.else.transform(self)
          else_vars = @vars.clone
        end
        else_dead_code = @dead_code
      end

      new_then_vars = []
      new_else_vars = []

      all_vars = []
      all_vars.concat then_vars.keys if then_vars
      all_vars.concat else_vars.keys if else_vars
      all_vars.uniq!

      all_vars.each do |var_name|
        before_indices = before_vars[var_name]
        then_indices = then_vars && then_vars[var_name]
        else_indices = else_vars && else_vars[var_name]
        if else_indices.nil?
          if before_indices
            if then_indices != before_indices
              push_assign_var_with_indices new_else_vars, var_name, before_indices[:write], before_indices[:read]
            end
          else
            push_assign_var_with_indices new_then_vars, var_name, then_indices[:write], then_indices[:read]
            push_assign_var_with_indices new_else_vars, var_name, then_indices[:write], nil
            @vars[var_name] = {read: then_indices[:write], write: then_indices[:write] + 1}
          end
        elsif then_indices.nil?
          if before_indices
            if else_indices != before_indices
              push_assign_var_with_indices new_then_vars, var_name, before_indices[:write], before_indices[:read]
            end
          else
            push_assign_var_with_indices new_else_vars, var_name, else_indices[:write], else_indices[:read]
            push_assign_var_with_indices new_then_vars, var_name, else_indices[:write], nil
            @vars[var_name] = {read: else_indices[:write], write: else_indices[:write] + 1}
          end
        elsif then_indices != else_indices
          then_write = then_indices[:write]
          else_write = else_indices[:write]
          max_write = then_write > else_write ? then_write : else_write
          push_assign_var_with_indices new_then_vars, var_name, max_write, then_indices[:read]
          push_assign_var_with_indices new_else_vars, var_name, max_write, else_indices[:read]
          @vars[var_name] = {read: max_write, write: max_write + 1}
        end
      end

      node.then = concat_preserving_return_value(node.then, new_then_vars)
      node.else = concat_preserving_return_value(node.else, new_else_vars)

      @dead_code = then_dead_code && else_dead_code

      node
    end

    def transform_while(node)
      before_cond_vars = @vars.clone
      node.cond = node.cond.transform(self)
      after_cond_vars = @vars.clone

      node.body = node.body.transform(self) if node.body

      after_body_vars = get_loop_vars(after_cond_vars, false)
      after_body_vars.concat get_loop_vars(before_cond_vars, false)
      after_body_vars.uniq!

      @vars.each do |var_name, indices|
        after_indices = after_cond_vars[var_name]
        if after_indices && after_indices != indices
          @vars[var_name] = {read: after_indices[:read], write: indices[:write]}
        end
      end

      node.body = concat_preserving_return_value(node.body, after_body_vars)

      node
    end

    def transform_call(node)
      node.obj = node.obj.transform(self) if node.obj
      node.args.map! { |arg| arg.transform(self) }

      if node.block
        before_vars = @vars.clone

        node.block.args.each do |arg|
          @vars[arg.name] = {read: 0, write: 1}
        end

        node.block.transform(self)

        node.block.args.each do |arg|
          @vars.delete arg.name
        end

        after_body_vars = get_loop_vars(before_vars)

        node.block.body = concat_preserving_return_value(node.block.body, after_body_vars)
      end

      node
    end

    def concat_preserving_return_value(node, vars)
      return node if vars.empty?

      unless node
        vars.push NilLiteral.new
        return Expressions.from(vars)
      end

      temp_var = new_temp_var
      assign = Assign.new(temp_var, node)
      vars.push temp_var

      Expressions.concat(assign, vars)
    end

    def increment_var(name, indices = @vars[name])
      @vars[name] = {read: indices[:write], write: indices[:write] + 1}
    end

    def get_loop_vars(before_vars, restore = true)
      loop_vars = []

      @vars.each do |var_name, indices|
        before_indices = before_vars[var_name]
        if before_indices && before_indices[:read] && before_indices[:read] < indices[:read]
          loop_vars << assign_var_with_indices(var_name, before_indices[:read], indices[:read])
          if restore
            @vars[var_name] = {read: before_indices[:read], write: indices[:write]}
          end
        end
      end

      loop_vars
    end

    def transform_var(node)
      return node if node.name == 'self' || node.name.start_with?('#')

      if node.out
        @vars[node.name] = {read: 0, write: 1}
        return node
      end

      indices = @vars[node.name]
      binding.pry unless indices
      node.name = var_name_with_index(node.name, indices[:read])
      node
    end

    def pushing_vars(vars = {})
      @vars, old_vars = vars, @vars
      @vars = vars
      @vars_stack.push vars
      yield
      @vars = old_vars
      @vars_stack.pop
    end

    def var_name_with_index(name, index)
      if index && index > 0
        "#{name}:#{index}"
      else
        name
      end
    end

    def var_with_index(name, index)
      Var.new(var_name_with_index(name, index))
    end

    def new_temp_var
      program.new_temp_var
    end

    def assign_var_with_indices(name, to_index, from_index)
      if from_index
        from_var = var_with_index(name, from_index)
      else
        from_var = NilLiteral.new
      end
      Assign.new(var_with_index(name, to_index), from_var)
    end

    def push_assign_var_with_indices(vars, name, to_index, from_index)
      return if to_index == from_index
      vars << assign_var_with_indices(name, to_index, from_index)
    end
  end
end