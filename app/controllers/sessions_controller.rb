class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: [:new]

  # GET /sessions/new
  def new
    @session = Session.new
    render layout: "authentication"
  end
end
