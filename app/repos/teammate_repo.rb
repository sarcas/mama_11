# frozen_string_literal: true

module Mama11
  module Repos
    class TeammateRepo < Mama11::DB::Repo
      def all
        teammates.order(teammates[:name].asc).to_a
      end

      def create(attributes)
        teammates.changeset(:create, attributes).commit
      end

      def remove(id)
        teammates.by_pk(id).delete
      end
    end
  end
end
