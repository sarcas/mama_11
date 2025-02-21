# frozen_string_literal: true

module Mama11
  module Actions
    module Teammate
      class Destroy < Mama11::Action
        include Deps["repos.teammate_repo"]

        params do
          required(:id).filled(:integer)
        end

        def handle(request, response)
          if request.params.valid?
            teammate_repo.remove(request.params[:id])
            response.redirect_to routes.path(:home)
          end
        end
      end
    end
  end
end
