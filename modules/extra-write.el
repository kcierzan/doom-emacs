;; extra-write.el

;; This library offers the following:
;;   + Write-mode: a mode that turns Emacs into an app for writing notes, papers, or
;;     fiction: it adds eye-candy to org-mode, switches to a light color theme and
;;     to a more readable font.
;;   + Bibtex integration

;; Write-mode settings
(defconst write-mode nil)
(defconst write-mode-font (font-spec :family "Hack" :size 12))
(defconst write-mode-biblio-dir "~/Dropbox/docs/biblio")

(defconst write-mode--last-mode-line mode-line-format)
(defconst write-mode--last-line-spacing line-spacing)

;;
(setq-default visual-fill-column-center-text nil
              visual-fill-column-width 80)

(defun write-mode|org-hook ()
  "A hook that runs everytime an org-mode buffer is visited/created while `write-mode' is
active."
  ;; (font-lock-add-keywords nil write-mode-org-font-lock-keywords)
  )

(defun write-mode-toggle ()
  "Enable write-mode, this is not a [global] minor mode because it mixes some frame-local
functionality with buffer-local ones, which can be buggy in a minor-mode."
  (interactive)
  (let* ((mode-p write-mode)
         (on-off (if mode-p -1 +1)))
    ;; (scroll-bar-mode on-off)
    (narf/load-font (if mode-p narf-default-font write-mode-font))
    (when (featurep 'volatile-highlights)
      (volatile-highlights-mode (not on-off)))
    (when IS-MAC
      (setq mouse-wheel-scroll-amount
            (if mode-p '(5 ((shift) . 2)) '(3 ((shift) . 2)))))
    (if write-mode
        (remove-hook 'org-mode-hook 'write-mode|org-hook)
      (add-hook 'org-mode-hook 'write-mode|org-hook))
    (mapc (lambda (b)
            (with-current-buffer b
              (setq line-spacing (if mode-p write-mode--last-line-spacing '2))
              (when (eq major-mode 'org-mode)
                (unless write-mode
                    ;; (font-lock-remove-keywords nil write-mode-org-font-lock-keywords)
                  (write-mode|org-hook))
                (org-bullets-mode on-off))))
          (narf/get-buffers-in-modes '(org-mode markdown-mode)))
    (setq write-mode (not write-mode))))

(evil-define-command narf:set-columns (&optional bang columns)
  "Adjusts visual-fill-column-width on the fly."
  (interactive "<!><a>")
  (if (or (= (length columns) 0) bang)
      (progn
        (setq visual-fill-column-width 80)
        (when visual-fill-column-mode
          (visual-fill-column-mode -1)))
    (setq columns (string-to-number columns))
    (when (> columns 30)
      (setq visual-fill-column-width columns)))
    (if visual-fill-column-mode
        (visual-fill-column--adjust-window)
      (visual-fill-column-mode 1)))

(when (>= emacs-major-version 25)
  ;; From <https://github.com/joostkremers/visual-fill-column/pull/6>
  ;; Splitting windows while visual-fill-column makes Emacs go crazy. This prevents that
  ;; by simply disabled VFC before splitting.
  (after! visual-fill-column
    (advice-add 'split-window :around #'visual-fill-column--disable-on-split-window))
  (defun visual-fill-column--disable-on-split-window (fn window &rest args)
    "Undo the effects of `visual-fill-column-mode' for splitting window."
    (if (and (or (not window) (window-live-p window))
             (buffer-local-value 'visual-fill-column-mode
                                 (window-buffer (or window (selected-window)))))
        (let ((inhibit-redisplay t))
          (set-window-fringes (or window (selected-window)) nil)
          (set-window-margins (or window (selected-window)) 0 0)
          (unwind-protect (apply fn window args)
            (save-selected-window
              (when window (select-window window 'norecord))
              (visual-fill-column--adjust-window))))
      (apply fn window args))))


(provide 'extra-write)
;;; extra-write.el ends here