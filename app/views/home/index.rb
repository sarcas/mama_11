# frozen_string_literal: true

module Mama11
  module Views
    module Home
      class Index < Mama11::View
        include Deps["repos.teammate_repo"]

        expose :teammates do
          teammate_repo.all
        end
      end
    end
  end
end
