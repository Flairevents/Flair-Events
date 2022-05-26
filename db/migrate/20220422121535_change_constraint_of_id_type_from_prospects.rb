class ChangeConstraintOfIdTypeFromProspects < ActiveRecord::Migration[5.2]
  def up
    execute "ALTER TABLE prospects DROP CONSTRAINT prospects_id_type_check"
    execute "ALTER TABLE prospects ADD CONSTRAINT prospects_id_type_check CHECK (((id_type)::text = ANY (ARRAY[('UK Passport'::character varying)::text, ('EU Passport'::character varying)::text, ('Work/Residency Visa'::character varying)::text, ('BC+NI'::character varying)::text, ('Pass Visa'::character varying)::text])))"
  end
  def down
    execute "ALTER TABLE prospects DROP CONSTRAINT prospects_id_type_check"
    execute "ALTER TABLE prospects ADD CONSTRAINT prospects_id_type_check CHECK (((id_type)::text = ANY (ARRAY[('UK Passport'::character varying)::text, ('EU Passport'::character varying)::text, ('Work/Residency Visa'::character varying)::text, ('BC+NI'::character varying)::text])))"
  end
end