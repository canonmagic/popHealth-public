# The list of log actions comes from the MU specification on audit reports, and the
# types of actions to capture.  We supplement the first part of the lsit with some
# additional actions that may be of interest.

module LogAction
  CREATE = "Add"
  READ = "Read"
  UPDATE = "Update"
  DELETE = "Delete"
  SEARCH = "Query"
  IMPORT = "Import"
  EXPORT = "Export"
  PRINT = "Print"
  COPY = "Copy"
  ACCESS_PATIENT_INFORMATION = "Access to patient information"
  EMERGENCY_ACCESS_PATIENT_INFORMATION = "Emergency access to patient information"
  CHANGE_USER_PRIVILEGIES = "Update of user privileges"
  CHANGE_AUDIT_STATUS = "Audit status changed"
  CHANGE_ENCRYPT_STATUS = "Encryption status changed"
  AUTHENTICATION = "Authentication"
end