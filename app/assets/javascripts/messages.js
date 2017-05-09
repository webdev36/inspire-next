var ready, set_positions;
set_positions = function(){
    $('tr.message-row').each(function(i){
        $(this).attr("data-pos",i+1);
    });
}
ready = function(){
    set_positions();
    $('.sortable').sortable();
}
$(document).ready(ready);
