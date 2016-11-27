# this writes an html file to the tmp folder

def write_html_to_temp
  name = "#{SecureRandom.urlsafe_base64}.html"
  Files.write_to_tmp_path(name, page.html)
  return name
end
