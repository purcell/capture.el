;;; capture-helper --- helper functions
;;; Commentary:
;;; Code:

(require 'capture-vars)

(defun string/starts-with (s arg)
  "Return non-nil if string S starts with ARG.  Else nil."
  (cond ((>= (length s) (length arg))
         (string-equal (substring s 0 (length arg)) arg))
        (t nil)))

(defun capture-run-daemonized-command (cmd &optional buf)
  "Run a system command CMD.
That will continue to work even after you kill Emacs.
BUF - for `async-shell-command'."
  (save-window-excursion
    (if buf
        (async-shell-command (concat "nohup " cmd " >/dev/null 2>&1") buf)
      (async-shell-command (concat "nohup " cmd " >/dev/null 2>&1")))))

(defun capture-run-daemonized-command-no-buf (cmd)
  "Run a shell command CMD deatached from process.
Do not show any buffers."
  (interactive)
  (let ((buf (generate-new-buffer "**capture-async-command**")))
    (capture-run-daemonized-command cmd buf)
    (run-with-timer 3 nil (lambda (buf)
                            (let (kill-buffer-query-functions)
                              (kill-buffer buf))) buf)))

(defun set-desktop-background (filename)
  "Change desktop background to the FILENAME."
  (interactive)
  (if (file-exists-p filename)
      (shell-command
       (concat "gsettings set org.gnome.desktop.background picture-uri file://" filename))
    (message (concat "No file: " filename))))

(defun capture-get-audio-devices-helper ()
  "Return an output of \"pactl list\" command."
  (interactive)
  (let ((cmd "pactl list | awk '/^Source .*/{f=1}f;/Description/{f=0}' | awk '/Name/{f=1}f;/Desc/{f=0}' | awk '{ sub(/^[ \t]+(Name|Description): /, \"\"); print }'"))
    ;;pactl list | grep "Source #"
    (shell-command-to-string cmd)))
;; (capture-get-audio-devices-helper)



(defun capture-get-audio-devices (&optional force)
  "Get audio devices and write them to variables as lists.
`capture-audio-speakers' - \"What you hear\"
`capture-audio-microphones' - your mics
Use FORCE to update the list of devices."
  (interactive)
  (if (or force
          (and (= (length capture-audio-speakers) 0)
               (= (length capture-audio-microphones) 0)))
      (let ((pyfile (concat (file-name-directory (locate-library "capture"))
                            "listaudio.py"))
            devices)
        ;;(setq devices (split-string (shell-command-to-string pyfile) "---"))
        (setq devices (split-string (capture-get-audio-devices-helper) "\n"))

        (setq capture-audio-speakers nil)
        (setq capture-audio-microphones nil)

        (let ((index 0) devname title)
              (dolist (element devices)
                (if (= (% index 2) 1)
                    (progn
                      (setq title element)
                      (if (string/starts-with title "Monitor")
                          (setq capture-audio-speakers
                                (append capture-audio-speakers (list devname title)))
                        (setq capture-audio-microphones
                              (append capture-audio-microphones (list devname title)))))
                  (setq devname element))
                (setq index (+ index 1))))
        ;;(setq capture-audio-speakers
        ;;      (nbutlast (split-string (car devices) "\n") 1))
        ;;(setq capture-audio-microphones
        ;;      (cdr (nbutlast (split-string (car (cdr devices)) "\n") 1))))))
        )))
;; (capture-get-audio-devices t)
;; (shell-command-to-string (concat (file-name-directory (locate-library "capture")) "listaudio.py"))
;; capture-audio-speakers
;; capture-audio-microphones

(defun capture-get-audio-name-by-title (title)
  "Return audio device system name by TITLE."
  (interactive)
  (let (prev current res (index 0))
    (dolist (element (append capture-audio-speakers
                             capture-audio-microphones) res)
      (if (= (% index 2) 1)
          (progn
            (setq current element)
            (if (string= current title)
                (setq res prev)))
        (setq prev element))
      (setq index (+ index 1)))))


(provide 'capture-helpers)
;;; capture-helpers.el ends here
