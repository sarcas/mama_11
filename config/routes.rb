# frozen_string_literal: true

module Mama11
  class Routes < Hanami::Routes
    # Add your routes here. See https://guides.hanamirb.org/routing/overview/ for details.
    get "/", to: "home.index", as: :home
    get "/teammate/new", to: "teammate.new", as: :new_teammate
    post "/teammate", to: "teammate.create", as: :create_teammate
    delete "/teammate/:id", to: "teammate.destroy", as: :remove_teammate
    get "/teammate/:id", to: "teammate.show", as: :show_teammate
    get "/teammate/:id/edit", to: "teammate.edit", as: :edit_teammate
    patch "/teammate/:id", to: "teammate.update", as: :update_teammate
  end
end
