jQuery ->
  if $('#sortable').length > 0
    table_width = $('#sortable').width()
    cells = $('.table').find('tr')[0].cells.length
    desired_width = table_width / cells + 'px'
    $('.table td').css('width', desired_width)

    $('#sortable').sortable(
      axis: 'y'
      items: '.item'
      cursor: 'move'

      sort: (e, ui) ->
        ui.item.addClass('active-item-shadow')
      stop: (e, ui) ->
        ui.item.removeClass('active-item-shadow')
        # highlight the row on drop to indicate an update
        ui.item.children('td').effect('highlight', {}, 1000)
      update: (e, ui) ->
        item_id = ui.item.data('item-id')
        channel_id = ui.item.data('channel-id')
        console.log(item_id)
        position = ui.item.index() + 1# this will not work with paginated items, as the index is zero on every page
        post_url = "/channels/" + channel_id + '/messages/update_seq_no';
        $.ajax(
          type: 'POST'
          url: post_url
          dataType: 'json'
          data: { message: {id: item_id, seq_no_position: position } }
        )
    )
