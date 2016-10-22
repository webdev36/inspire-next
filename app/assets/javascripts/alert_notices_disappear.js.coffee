$(document).on 'page:load', ->
  $('.alert-info').fadeTo(2000, 500).slideUp 500, ->
    $('.alert-info').slideUp 500
    return
  return
