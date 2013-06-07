class User
  def initialize(options)
    @remote = partner.login_user(options["username"], options["password"])
  end

  def stations
    @remote.stations
  end

  protected

  def partner
    Pandora::Partner.new("iphone",
                         "P2E4FC0EAD3*878N92B2CDp34I0B1@388137C",
                         "IP01",
                         "721^26xE22776",
                         "20zE1E47BE57$51")
  end
end
