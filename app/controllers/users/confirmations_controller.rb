class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      sign_in(resource)
      redirect_to root_path, notice: "Your email has been confirmed. Welcome!"
    else
      redirect_to new_session_path(resource_name), alert: resource.errors.full_messages.to_sentence
    end
  end
end
