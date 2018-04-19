class AddFunctionWithLanguage < ActiveRecord::Migration
  def change
    create_function 'pets_can_speak()', :boolean, <<-FUNCTION.gsub(/^[\s]{6}/, ""), language: 'sql'
      SELECT true;
    FUNCTION
  end
end
