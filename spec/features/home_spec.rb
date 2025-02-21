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

  scenario "allows me to add new teammates" do
    visit "/"

    expect(page).to have_selector "li", count: 3

    click_link "Add Teammate"
    fill_in "Name", with: "Clyde"
    click_button "Add"

    expect(page).to have_selector "li", count: 4
    expect(page).to have_selector "li", text: "Clyde"
    expect(page).to have_selector "li", text: "Dick Dastardly"
    expect(page).to have_selector "li", text: "Muttley"
    expect(page).to have_selector "li", text: "Penelope Pitstop"
  end

  scenario "allows me to remove teammates I no longer have contact with :'/" do
    visit "/"

    expect(page).to have_selector "li", count: 3

    click_button "Remove Dick Dastardly"

    expect(page).to have_selector "li", count: 2
    expect(page).to have_selector "li", text: "Muttley"
    expect(page).to have_selector "li", text: "Penelope Pitstop"
  end

  scenario "I can get to a teammate page from home" do
    visit "/"
    
    click_link "Penelope Pitstop"

    expect(page).to have_text "Penelope Pitstop"
    expect(page).not_to have_text "Muttley"
  end

end
