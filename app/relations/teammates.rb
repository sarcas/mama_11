# frozen_string_literal: true

module Mama11
  module Relations
    class Teammates < Mama11::DB::Relation
      schema :teammates, infer: true
    end
  end
end
