# Policy for Proposals, though for now covering blind review functionality.
class ProposalPolicy < ApplicationPolicy
  def reviewer?
    @user.staff_for?(@current_event)
  end

  def review?
    @user.staff_for?(@current_event) && !@record.has_speaker?(@user)
  end

  def review_as_organizer?
    @user.organizer_for_event?(@current_event)
  end

  def rate?
    @user.staff_for?(@current_event)
  end

  def update_state?
    @user.program_team_for_event?(@current_event)
  end

  def update_track?
    @user.program_team_for_event?(@current_event)
  end

  def update_session_format?
    @user.program_team_for_event?(@current_event)
  end

  def finalize?
    @user.organizer_for_event?(@current_event)
  end

  def confirm_for_speaker?
    @user.organizer_for_event?(@current_event)
  end

  def destroy?
    @user.organizer_for_event?(@current_event)
  end

  class Scope < ApplicationScope
    def resolve
      @current_event.proposals.not_withdrawn.not_owned_by(@user)
    end
  end
end
