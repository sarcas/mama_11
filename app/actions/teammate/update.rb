# frozen_string_literal: true

module Mama11
  module Actions
    module Teammate
      class Update < Mama11::Action
        include Deps["repos.teammate_repo"]

        params do
          required(:teammate).hash do
            required(:name).filled(:string)
          end
          required(:id).filled(:integer)
        end

        def handle(request, response)
          if request.params.valid?
            teammate = teammate_repo.update(request.params[:teammate])
            response.redirect_to routes.path(:show_teammate, id: teammate[:id])
          end
        end
      end
    end
  end
end
