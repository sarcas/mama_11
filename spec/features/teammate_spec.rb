# frozen_string_literal: true

RSpec.feature "Teammate" do
  before do
    teammates = Hanami.app["relations.teammates"]
    teammates.insert(name: "Penelope Pitstop", id: 1)
  end

  scenario "allows me to change the teammate's name" do
    visit "/teammate/1"

    expect(page).to have_text "Penelope Pitstop"
    
    click_link "Edit"
    fill_in "Name", with: "Penny Pitstop"
    click_button "Save" 

    expect(page).to have_text "Penny Pitstop"
  end

  scenario "allows me to remove the teammate"
  scenario "allows me to create meetings"
  scenario "allows me to select a meeting"
  scenario "allows me to set a sentiment for a meeting"
  scenario "allows me to add notes to selected meeting"
  scenario "allows me to view the notes from previous 1:1 meeting"
  scenario "allows me to generate summary for teammate by date"
end
