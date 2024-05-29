class UsersController < ApplicationController
  skip_before_action :authenticate!, only: [ :new ]

  # GET /users/new
  def new
    @user = User.new
    render layout: "authentication"
  end
end
