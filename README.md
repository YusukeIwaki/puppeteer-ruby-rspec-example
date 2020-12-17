# puppeteer-ruby + RSpec + PageObject のサンプル

```
class Notification < PageObject
  element :el_message, '.content'
  element :el_timestamp, '.timestamp'

  def message
    el_message.evaluate('(el) => el.textContent')
  end
end

class Dashboard < PageObject
  element :logo, "#img-logo"
  sections :notifications, Notification, ".notification-item"
end

~~~

it {
  page.goto('http://example.com/top')

  dashboard = Dashboard.new(page)
  expect(dashboard.notifications.first).to eq('Admin is logged in')
}
```
