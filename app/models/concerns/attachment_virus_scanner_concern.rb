# Enqueue a virus-scan job when an attachment is created.
#
# NB: this could be a good use case for an ActiveStorage::Analyzer,
# but only the first matching Analyzer is ever run – and we may want
# to both scan for viruses *and* extract images metadata.
module AttachmentVirusScannerConcern
  extend ActiveSupport::Concern

  included do
    before_create :set_virus_scan_pending
    after_create_commit :enqueue_virus_scan
  end

  def virus_scanner
    ActiveStorage::VirusScanner.new(blob)
  end

  private

  def set_virus_scan_pending
    blob.update!(metadata: blob.metadata.merge(virus_scan_result: ActiveStorage::VirusScanner::PENDING))
  end

  def enqueue_virus_scan
    if !virus_scanner.done?
      VirusScannerJob.perform_later(blob)
    end
  end
end
