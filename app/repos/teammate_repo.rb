# frozen_string_literal: true

module Mama11
  module Repos
    class TeammateRepo < Mama11::DB::Repo
      def all
        teammates.order(teammates[:name].asc).to_a
      end
    end
  end
end
