module Capybara::Paparazzi::Driver

  def capybara_paparazzi_settings
    @capybara_paparazzi_settings ||= {}
  end

  def visit(*args)
    response = super(*args)
    Capybara::Paparazzi.take_snapshots(self, :visit, args)
    response
  end

end
