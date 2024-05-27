class SessionsController < ApplicationController
  # GET /sessions/new
  def new
    @session = Session.new
    render layout: "authentication"
  end
end
