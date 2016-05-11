;;; extract-package-url.el --- Extract Package URL

;; Copyright (C) 2016  Chunyang Xu
;;
;; License: GPLv3

;;; Commentary:
;;
;; Usage: elpa=the-name-of-elpa emacs -Q --batch -l extract-package-url.el

;;; Code:

(defvar extract-package-url-source-mapping
  '((gnu          . "http://elpa.gnu.org/packages/")
    (melpa        . "http://melpa.org/packages/")
    (melpa-stable . "http://stable.melpa.org/packages/")
    (marmalade    . "http://marmalade-repo.org/packages/")
    (SC           . "http://joseito.republika.pl/sunrise-commander/")
    (org          . "http://orgmode.org/elpa/"))
  "Mapping of source name and url.")

(defun extract-package-url (elpa)
  (let* ((name elpa)
         (url
          (and name
               (cdr (assq (intern name) extract-package-url-source-mapping)))))
    (unless url (error "Unknown ELPA: %s" name))
    (let ((ac-url (concat url "archive-contents"))
          (ac-file (expand-file-name "archive-contents" name)))
      (url-copy-file ac-url ac-file t)
      (shell-command (concat "chmod a+r " ac-file))
      ;; Download signature file for GNU ELPA
      (when (string-equal "gnu" name)
        (url-copy-file (concat ac-url ".sig") (concat ac-file ".sig") t)
        (shell-command (concat "chmod a+r " (concat ac-file ".sig"))))
      (with-temp-buffer
        (insert-file-contents ac-file)
        (dolist (pkg (cdr (read (buffer-string))))
          (let ((pkg-name (car pkg))
                (pkg-version (mapconcat #'number-to-string
                                        (aref (cdr pkg) 0)
                                        "."))
                (pkg-type (if (eq 'tar (aref (cdr pkg) 3))
                              "tar" "el")))
            (princ (format "%s%s-%s.%s\n" url pkg-name pkg-version pkg-type))
            (princ (format "%s%s-readme.txt\n" url pkg-name))
            ;; Download signature file for GNU ELPA
            (when (string-equal "gnu" name)
              (princ (format "%s%s-%s.%s.sig\n" url pkg-name pkg-version pkg-type)))))))))

(extract-package-url (getenv "elpa"))

;;; extract-package-url.el ends here
