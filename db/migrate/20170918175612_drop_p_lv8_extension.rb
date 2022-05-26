class DropPLv8Extension < ActiveRecord::Migration[5.1]
  def change
    # This Postgres extension is not being used any more
    execute "DROP FUNCTION title_case(input_str varchar)"
    execute "DROP EXTENSION IF EXISTS plv8"
    execute <<-'SQL'
CREATE OR REPLACE FUNCTION title_case(str varchar) RETURNS varchar AS $$
DECLARE
  punct varchar = E'[\'\\[\\]\\\\!"#$%&()*+,./:;<=>?@^_`{|}~-]';
BEGIN
  str := initcap(str); -- capitalize first letter of each word
  -- avoid capitalizing short grammar words like 'the' and 'an', unless they appear
  --   at the beginning of a sentence
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)a\M',   '\1a',   'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)an\M',  '\1an',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)and\M', '\1and', 'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)as\M',  '\1as',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)at\M',  '\1at',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)but\M', '\1but', 'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)by\M',  '\1by',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)for\M', '\1for', 'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)if\M',  '\1if',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)in\M',  '\1in',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)of\M',  '\1of',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)on\M',  '\1on',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)or\M',  '\1or',  'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)the\M', '\1the', 'i');
  str := regexp_replace(str, '(?!' || punct || '\s*)(\S\s*)to\M',  '\1to',  'i');
  -- special case for names like 'McDonald'
  str := regexp_replace(str, '\mmca', 'McA', 'i');
  str := regexp_replace(str, '\mmcb', 'McB', 'i');
  str := regexp_replace(str, '\mmcc', 'McC', 'i');
  str := regexp_replace(str, '\mmcd', 'McD', 'i');
  str := regexp_replace(str, '\mmce', 'McE', 'i');
  str := regexp_replace(str, '\mmcg', 'McG', 'i');
  str := regexp_replace(str, '\mmch', 'McH', 'i');
  str := regexp_replace(str, '\mmck', 'McK', 'i');
  str := regexp_replace(str, '\mmcl', 'McL', 'i');
  str := regexp_replace(str, '\mmcm', 'McM', 'i');
  str := regexp_replace(str, '\mmcn', 'McN', 'i');
  str := regexp_replace(str, '\mmcp', 'McP', 'i');
  str := regexp_replace(str, '\mmcq', 'McQ', 'i');
  str := regexp_replace(str, '\mmcr', 'McR', 'i');
  str := regexp_replace(str, '\mmcs', 'McS', 'i');
  str := regexp_replace(str, '\mmct', 'McT', 'i');
  str := regexp_replace(str, '\mmcw', 'McW', 'i');
  RETURN str;
END
$$ LANGUAGE plpgsql;
SQL
  end
end
