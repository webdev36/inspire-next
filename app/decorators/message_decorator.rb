class MessageDecorator < Draper::Decorator
  delegate_all

  def title_text
    case
    when type == "ActionMessage"
      h.raw("<i class='fa fa-gears' title='Take action on behalf of subscriber'></i> #{action.as_text}")
    else
      h.raw("<i class='fa fa-envelope' title='Send a message to a subscriber'></i> #{caption.to_s[0..100]}")
    end
  end

end
