namespace :after_party do
  desc 'Deployment task: backfill_avis_claimant_type'
  task backfill_avis_claimant_type: :environment do
    puts "Running deploy task 'backfill_avis_claimant_type'"

    Avis.where(claimant_type: nil)
      .each do |avis|
        instructeur = Instructeur.find(avis.claimant_id)
        expert = instructeur&.user&.expert

        if instructeur.present? && instructeur.dossiers.present?
          avis.update_column(:claimant_type, "Instructeur")
        elsif expert.present?
          avis.update_columns(claimant_id: expert.id, claimant_type: "Expert")
        else
          puts "Expert not found for #{avis.id}"
        end
      end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
