json.data @grade_scheme_elements do |gse|
  json.type "grade_scheme_elements"
  json.id gse.id.to_s
  json.attributes do
    json.merge! gse.attributes
    json.name gse.name
  end
end

json.meta do
  json.total_points @total_points
end
