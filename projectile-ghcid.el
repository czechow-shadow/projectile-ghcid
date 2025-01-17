;;; projectile-ghcid -- Launch ghcid from your projectile root

(define-minor-mode ghcid-mode
  "A minor mode for ghcid terminals"
  :lighter " ghcid"
  (compilation-minor-mode))

;; FIXME: throw this one away
;; (defun ghcid-command ()
;;   "The command used to run ghcid."
;;   "ghcid\n")
(defgroup projectile-ghcid nil
  "Configuraion group for projectile-ghcid."
  :group 'tools
  :group 'convenience)

(defcustom ghcid-height 50
  "Set ghcid buffer window height."
  :group 'projectile-ghcid
  :type 'integer)

(defun get-or-create-ghcid-buffer (buf-name)
  "Select the buffer with name BUF-NAME."
  (let ((ghcid-buf (get-buffer-create buf-name)))
    (display-buffer
     ghcid-buf
     '((display-buffer-pop-up-window
        display-buffer-reuse-window)
       (window-height . ghcid-height)))
    (select-window (get-buffer-window ghcid-buf))))

(defun find-shell-nix ()
  "Find shell.nix file in the project dirs."
  (projectile-locate-dominating-file "." "shell.nix"))


(defun spawn-ghcid (buf-name)
  "Spawn ghcid inside the current buffer with BUF-NAME."
  (let ((shell-nix (find-shell-nix))) ;; FIXME: overkill here?
    (if shell-nix
        (make-term (format "ghcid: %s" (projectile-project-name))
                   "nix-shell" nil "--run"
                   (concat "ghcid -h " (number-to-string ghcid-height)
                           " --restart *.cabal --restart .ghcid"))
      (make-term (format "ghcid: %s" (projectile-project-name))
                 "ghcid" nil "-h" (number-to-string ghcid-height))))

  (term-mode)
  (term-line-mode)
  (setq-local scroll-up-aggressively 1)
  (setq-local window-point-insertion-type t)
  (setq-local term-buffer-maximum-size ghcid-height)
  (ghcid-mode))
  ;; (comint-send-string buf-name (ghcid-command)))


(defun run-ghcid (buf-name)
  "Run or display a ghcid buffer with the given BUF-NAME."
  (let ((cur (selected-window))
        (buf-exists (get-buffer buf-name)))
    (progn
      (get-or-create-ghcid-buffer buf-name)
      (if buf-exists (goto-char (point-max))
        (spawn-ghcid buf-name))
      (select-window cur))))

(defun ghcid-projectile-buf-name ()
  "Create the buffer name for the projectile project."
  (format "*ghcid: %s*" (projectile-project-name)))

(defun projectile-ghcid-stop ()
  "Stop ghcid for this project."
  (interactive)
  (let* ((buf-name (ghcid-projectile-buf-name))
         (ghcid-buf (get-buffer buf-name))
         (ghcid-window (get-buffer-window ghcid-buf))
         (ghcid-proc (get-buffer-process ghcid-buf)))
    (when ghcid-buf
      (progn
        (when (processp ghcid-proc)
          (progn
            (set-process-query-on-exit-flag ghcid-proc nil)
            (kill-process ghcid-proc)))))
        (select-window ghcid-window)
        (kill-buffer-and-window)))

(defun projectile-ghcid-switch-to-buffer ()
  "Switch to an active ghcid buffer."
  (interactive)
  (projectile-with-default-dir (projectile-project-root)
    (let ((buf-name (ghcid-projectile-buf-name)))
      (get-or-create-ghcid-buffer buf-name))))

(defun projectile-ghcid ()
  "Spawn ghcid in the project root."
  (interactive)
  (projectile-with-default-dir (projectile-project-root)
    (let ((buf-name (ghcid-projectile-buf-name)))
      (run-ghcid buf-name))))

(provide 'projectile-ghcid)
