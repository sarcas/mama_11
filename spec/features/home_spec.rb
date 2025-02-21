# frozen_string_literal: true

RSpec.feature "Home" do
  let(:teammates) { Hanami.app["relations.teammates"] }

  before do
    teammates.insert(name: "Muttley")
    teammates.insert(name: "Penelope Pitstop")
    teammates.insert(name: "Dick Dastardly")
  end

  scenario "visiting home shows existing teammates" do
    visit "/"

    expect(page).to have_selector "li", count: 3
    expect(page).to have_selector "li", text: "Dick Dastardly"
    expect(page).to have_selector "li", text: "Muttley"
    expect(page).to have_selector "li", text: "Penelope Pitstop"
  end

  scenario "home allows me to add new teammates"
  scenario "home allows me to remove teammates I no longer need"
  scenario "I can get to a teammate page from home"
end
