# Pin npm packages by running ./bin/importmap

pin "jquery", to: "https://code.jquery.com/jquery-3.7.0.js", preload: true
pin "underscore", to: "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.13.6/underscore-min.js", preload: true
pin "application"

# JQuery
pin "jquery-idletimer", to: "https://ga.jspm.io/npm:jquery-idletimer@1.0.0/Gruntfile.js"
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
