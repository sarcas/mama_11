# frozen_string_literal: true

module Mama11
  module Views
    module Teammate
      class Show < Mama11::View
        include Deps["repos.teammate_repo"]

        expose :teammate do |id:|
          teammate_repo.find(id)
        end
      end
    end
  end
end
