class CreateFunctionWithArgs < ActiveRecord::Migration
  def change
    create_function 'get_pet(petname character varying, pet_type character varying)', :varchar, <<-FUNCTION.gsub(/^[\s]{6}/, ""), schema: 'public'
      BEGIN
        RETURN "corgi";
      END;
    FUNCTION
  end
end
