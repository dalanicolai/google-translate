;;; google-translate-core-ui.el --- google translate core UI

;; Copyright (C) 2012 Oleksandr Manzyuk <manzyuk@gmail.com>

;; Author: Oleksandr Manzyuk <manzyuk@gmail.com>
;; Maintainer: Andrey Tykhonov <atykhonov@gmail.com>
;; URL: https://github.com/atykhonov/google-translate
;; Version: 0.10.4
;; Keywords: convenience

;; Contributors:
;;   Tassilo Horn <tsdh@gnu.org>
;;   Bernard Hurley <bernard@marcade.biz>
;;   Chris Bilson <cbilson@pobox.com>

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This script provides the most common functions and variables for
;; UI. It does not contain any interactive functions and overall is
;; not going to be used directly by means of
;; `execute-extended-command' (M-x). Its purpose to provide the most
;; valuable and useful functionality for packages and scripts which
;; provide UI.
;;
;; The most important functions are the following:
;;
;; - `google-translate-translate'
;;
;; - `google-translate-read-source-language'
;;
;; - `google-translate-read-target-language'
;;
;; `google-translate-translate' translates the given text from source language to
;; target language and shows a translation.

;; `google-translate-read-source-language' reads source language from minibuffer and
;; returns language abbreviation. `google-translate-read-target-language' reads
;; target language from minibuffer and returns language abbreviation.
;; 
;; Customization:

;; You can customize the following variables:
;;
;; - `google-translate-output-destination'
;;
;; - `google-translate-enable-ido-completion'
;;
;; - `google-translate-show-phonetic'
;;
;; - `google-translate-listen-program'
;;
;; `google-translate-output-destination' determines translation output
;; destination. If `nil' the translation output will be displayed in the pop up
;; buffer. If value equal to `echo-area' then translation outputs in the Echo
;; Area. And in case of `popup' the translation outputs to the popup tooltip using
;; `popup' package. If you would like output translation to the Echo Area you would
;; probably like to increase it because only part of translation could be visible
;; there. To increase echo area you could increase the value of
;; `max-mini-window-height' variable, for example: `(setq max-mini-window-height
;; 0.5)'.
;;
;; If `google-translate-enable-ido-completion' is non-NIL, the input
;; will be read with ido-style completion.
;;
;; The variable `google-translate-show-phonetic' controls whether the
;; phonetic spelling of the original text and its translation is
;; displayed if available.  If you want to see the phonetics, set this
;; variable to t.
;;
;; The variable `google-translate-listen-program' determines the program to use to
;; listen translations. By default the program looks for `mplayer' in the PATH, if
;; `mplayer' is found then listening function will be available and you'll see
;; `Listen' button in the buffer with the translation. You can use any other suitable
;; program. If you use Windows please download and unpack `mplayer' and add its path
;; (directory) to the system PATH variable. Please note that translation listening is
;; not available if `google-translate-output-destination' is set to `echo-area' or
;; `popup'.
;;
;; There are also six faces you can customize:
;;
;; - `google-translate-text-face', used to display the original text
;;   (defaults to `default')
;;
;; - `google-translate-phonetic-face', used to display the phonetics
;;   (defaults to `shadow')
;;
;; - `google-translate-translation-face', used to display the highest
;;   ranking translation (defaults to `default' with the `weight'
;;   attribute set to `bold')
;;
;; - `google-translate-suggestion-label-face' used to display the
;;   label for suggestion (defaults to `default' with the `foreground'
;;   attribute set to `red')
;;
;; - `google-translate-suggestion-face' used to display the suggestion
;;   in case of word is misspelled (defaults to `default' with the
;;   `slant' attribute set to `italic' and `underline' attribute set
;;   to `t')
;;
;; - `google-translate-listen-button-face' used to display the "Listen"
;;   button (defaults to `height' 0.8).
;;
;; For example, to show the translation in a larger font change the
;; `height' attribute of the face `google-translate-translation-face'
;; like so:
;;
;;   (set-face-attribute 'google-translate-translation-face nil :height 1.4)
;;
;;
;;; Code:
;;

(require 'cl)
(require 'google-translate-core)
(require 'google-translate-inline-editing)
(require 'ido)


(defvar google-translate-supported-languages-alist
  '(("Afrikaans"           . "af")
    ("Albanian"            . "sq")
    ("Arabic"              . "ar")
    ("Armenian"            . "hy")
    ("Azerbaijani"         . "az")
    ("Basque"              . "eu")
    ("Belarusian"          . "be")
    ("Bengali"             . "bn")
    ("Bulgarian"           . "bg")
    ("Chinese Simplified"  . "zh-CN")
    ("Chinese Traditional" . "zh-TW")
    ("Croatian"            . "hr")
    ("Czech"               . "cs")
    ("Danish"              . "da")
    ("Dutch"               . "nl")
    ("English"             . "en")
    ("Estonian"            . "et")
    ("Filipino"            . "tl")
    ("Finnish"             . "fi")
    ("French"              . "fr")
    ("Galician"            . "gl")
    ("Georgian"            . "ka")
    ("German"              . "de")
    ("Greek"               . "el")
    ("Gujarati"            . "gu")
    ("Haitian Creole"      . "ht")
    ("Hebrew"              . "iw")
    ("Hindi"               . "hi")
    ("Hungarian"           . "hu")
    ("Icelandic"           . "is")
    ("Indonesian"          . "id")
    ("Irish"               . "ga")
    ("Italian"             . "it")
    ("Japanese"            . "ja")
    ("Kannada"             . "kn")
    ("Korean"              . "ko")
    ("Latin"               . "la")
    ("Latvian"             . "lv")
    ("Lithuanian"          . "lt")
    ("Macedonian"          . "mk")
    ("Malay"               . "ms")
    ("Maltese"             . "mt")
    ("Norwegian"           . "no")
    ("Persian"             . "fa")
    ("Polish"              . "pl")
    ("Portuguese"          . "pt")
    ("Romanian"            . "ro")
    ("Russian"             . "ru")
    ("Serbian"             . "sr")
    ("Slovak"              . "sk")
    ("Slovenian"           . "sl")
    ("Spanish"             . "es")
    ("Swahili"             . "sw")
    ("Swedish"             . "sv")
    ("Tamil"               . "ta")
    ("Telugu"              . "te")
    ("Thai"                . "th")
    ("Turkish"             . "tr")
    ("Ukrainian"           . "uk")
    ("Urdu"                . "ur")
    ("Vietnamese"          . "vi")
    ("Welsh"               . "cy")
    ("Yiddish"             . "yi"))
  "Alist of the languages supported by Google Translate.

Each element is a cons-cell of the form (NAME . CODE), where NAME
is a human-readable language name and CODE is its code used as a
query parameter in HTTP requests.")

(defvar google-translate-translation-listening-debug nil
  "For debug translation listening purposes.")

(defvar google-translate-buffer-name "*Google Translate*"
  "Name of buffer into which outputs translations.")

(defvar google-translate-text-keymap
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (define-key map (kbd "q") 'quit-window)
    (define-key map (kbd "TAB") 'forward-button)
    map)
  "Keymap to apply to the text as a property.")

(defstruct gtos
  "google translate output structure contains miscellaneous
  information which intended to be outputed to the buffer, echo
  area or popup tooltip."
  source-language target-language text
  auto-detected-language text-phonetic translation
  translation-phonetic detailed-translation suggestion)

(defgroup google-translate-core-ui nil
  "Emacs core UI script for the Google Translate package."
  :group 'processes)

(defcustom google-translate-enable-ido-completion nil
  "If non-NIL, use `ido-completing-read' rather than
  `completing-read' for reading input."
  :group 'google-translate-core-ui
  :type  '(choice (const :tag "No"  nil)
                  (other :tag "Yes" t)))

(defcustom google-translate-show-phonetic nil
  "If non-NIL, try to show the phonetic spelling."
  :group 'google-translate-core-ui
  :type '(choice (const :tag "No"  nil)
                 (const :tag "Yes" t)))

(defcustom google-translate-listen-program
  (executable-find "mplayer")
  "The program to use to listen translations. By default the
program looks for `mplayer' in the PATH, if `mplayer' is found
then listening function will be available and you'll see `Listen'
button in the buffer with the translation. You can use any other
suitable program."
  :group 'google-translate-core-ui
  :type '(string))

(defcustom google-translate-output-destination
  nil
  "Determines where translation output will be displayed. If
`nil' the translation output will be displayed in the pop up
buffer (default). If value equals to `echo-area' then translation
outputs in the Echo Area. And in case of `popup' the translation
outputs to the popup tooltip using `popup' package."
  :group 'google-translate-core-ui
  :type '(symbol))

(defcustom google-translate-inline-editing
  nil
  "Determines whether inline editing will be enabled or not. This
  feature makes possible to edit translating text in the output
  buffer and translate it immediately without any needs to
  select, call `google-translate-smooth-translate' (or
  `google-translate-query-translate') function and then edit text
  in the minibuffer to translate some modification of original
  text. And of course it is much more easier and brings more
  convinience to edit text as a regular text in the usual
  buffer. This feature is only available if
  `google-translate-output-destination' is nil.")

(defface google-translate-text-face
  '((t (:inherit default)))
  "Face used to display the original text."
  :group 'google-translate-core-ui)

(defface google-translate-phonetic-face
  '((t (:inherit shadow)))
  "Face used to display the phonetic spelling."
  :group 'google-translate-core-ui)

(defface google-translate-translation-face
  '((t (:weight bold)))
  "Face used to display the probable translation."
  :group 'google-translate-core-ui)

(defface google-translate-suggestion-label-face
  '((t (:foreground "red")))
  "Face used to display the suggestion label."
  :group 'google-translate-core-ui)

(defface google-translate-suggestion-face
  '((t (:slant italic :underline t)))
  "Face used to display the suggestion."
  :group 'google-translate-core-ui)

(defface google-translate-listen-button-face
  '((t (:height 0.8)))
  "Face used to display button \"Listen\"."
  :group 'google-translate-core-ui)

(defun google-translate-supported-languages ()
  "Return a list of names of languages supported by Google Translate."
  (mapcar #'car google-translate-supported-languages-alist))

(defun google-translate-language-abbreviation (language)
  "Return the abbreviation of LANGUAGE."
  (if (string-equal language "Detect language")
      "auto"
    (cdr (assoc language google-translate-supported-languages-alist))))

(defun google-translate-language-display-name (abbreviation)
  "Return a name suitable for use in prompts of the language whose
abbreviation is ABBREVIATION."
  (if (string-equal abbreviation "auto")
      "unspecified language"
    (car (rassoc abbreviation google-translate-supported-languages-alist))))

(defun google-translate-paragraph (text face &optional output-format)
  "Return TEXT as a filled paragraph into the current buffer and
apply FACE to it. Optionally use OUTPUT-FORMAT. If READ-WRITE is
t then text will be editable."
  (let ((beg (point))
        (output-format
         (if output-format output-format "\n%s\n"))
        (inhibit-read-only t))
    (with-temp-buffer
      (let ((beg (point)))
        (insert (format output-format text))
        (facemenu-set-face face beg (point))
        (buffer-substring (point-min) (point-max))))))

(defun google-translate--translation-title (gtos format)
  "Return translation title which contains information about used
source and target languages."
  (let ((source-language (gtos-source-language gtos))
        (target-language (gtos-target-language gtos))
        (auto-detected-language (gtos-auto-detected-language gtos)))
    (format format
            (if (string-equal source-language "auto")
                (format "%s (detected)"
                        (google-translate-language-display-name
                         auto-detected-language))
              (google-translate-language-display-name
               source-language))
            (google-translate-language-display-name
             target-language))))

(defun google-translate--text-phonetic (gtos format)
  "Outputs in buffer text phonetic in case of
`google-translate-show-phonetic' is set to t."
  (let ((text-phonetic (gtos-text-phonetic gtos)))
    (if (and google-translate-show-phonetic
               (not (string-equal text-phonetic "")))
        (google-translate-paragraph
         text-phonetic
         'google-translate-phonetic-face
         format)
      "")))

(defun google-translate--translated-text (gtos format)
  "Output in buffer translation."
  (let ((translation (gtos-translation gtos)))
    (google-translate-paragraph
     translation
     'google-translate-translation-face
     format)))

(defun google-translate--translation-phonetic (gtos format)
  "Output in buffer translation phonetic in case of
`google-translate-show-phonetic' is set to t."
  (let ((translation-phonetic (gtos-translation-phonetic gtos)))
    (if (and google-translate-show-phonetic
               (not (string-equal translation-phonetic "")))
        (google-translate-paragraph
         translation-phonetic
         'google-translate-phonetic-face
         format)
      "")))

(defun google-translate--detailed-translation (detailed-translation translation
                                                                    format1
                                                                    format2)
  "Return detailed translation."
  (with-temp-buffer
    (loop for item across detailed-translation do
          (let ((index 0))
            (unless (string-equal (aref item 0) "")
              (insert (format format1 (aref item 0)))
              (loop for translation across (aref item 1) do
                    (insert (format format2
                                    (incf index) translation))))))
    (buffer-substring (point-min) (point-max))))

(defun google-translate--suggestion (gtos)
  "Return suggestion."
  (let ((source-language (gtos-source-language gtos))
        (target-language (gtos-target-language gtos))
        (suggestion (gtos-suggestion gtos)))
    (if suggestion
        (with-temp-buffer
          (insert "\n")
          (let ((beg (point)))
            (insert "Did you mean: ")
            (facemenu-set-face 'google-translate-suggestion-label-face
                               beg (point)))
          (goto-char (+ (point) 1))
          (let ((beg (point))
                (map (make-sparse-keymap)))
            (define-key map (kbd "<RET>") 'google-translate--suggestion)
            (define-key map (kbd "C-t") 'google-translate--suggestion)
            ;; (insert suggestion)
            ;; (put-text-property beg (point) 'keymap map)
            (insert-text-button suggestion
                                'action 'google-translate--suggestion-action
                                'follow-link t
                                'keymap map
                                'suggestion suggestion
                                'source-language source-language
                                'target-language target-language)
            (facemenu-set-face 'google-translate-suggestion-face
                               beg (point))
            (insert "\n"))
          (buffer-substring (point-min) (point-max)))
      "")))

(defun google-translate--suggestion-action (button)
  "Suggestion action which occur when suggestion button is
clicked."
  (interactive)
  (let ((suggestion (button-get button 'suggestion))
        (source-language (button-get button 'source-language))
        (target-language (button-get button 'target-language)))
    (google-translate-translate source-language
                                target-language
                                suggestion)))

(defun google-translate--translating-text (gtos format)
  "Outputs in buffer translating text."
  (let ((text (gtos-text gtos)))
    (let ((output-format format))
      (google-translate-paragraph
       text
       'google-translate-text-face
       output-format))))

(defun google-translate--listen-button (gtos)
  "Return listen button."
  (let ((language (gtos-source-language gtos))
        (text (gtos-text gtos)))
    (with-temp-buffer
      (insert " ")
      (let ((beg (point)))
        (insert-text-button "[Listen]"
                            'action 'google-translate--listen-action
                            'follow-link t
                            'text text
                            'language language)
        (facemenu-set-face 'google-translate-listen-button-face
                           beg (point))
        (insert "\n"))
      (buffer-substring (point-min) (point-max)))))

(defun google-translate--listen-action (button)
  "Do translation listening."
  (interactive)
  (let ((text (button-get button 'text))
        (language (button-get button 'language)))
    (google-translate-listen-translation language text)))

(defun google-translate-listen-translation (language text)
  (let ((buf "*mplayer output*"))
    (message "Retrieving audio message...")
    (if google-translate-translation-listening-debug
        (with-current-buffer (get-buffer-create buf)
          (insert (format "Listen program: %s\r\n" google-translate-listen-program))
          (insert (format "Listen URL: %s\r\n" (google-translate-format-listen-url text language)))
          (call-process google-translate-listen-program nil t nil
                        (format "%s" (google-translate-format-listen-url text language)))
          (switch-to-buffer buf))
      (call-process google-translate-listen-program nil nil nil
                    (format "%s" (google-translate-format-listen-url text language))))))

(defun google-translate-translate (source-language target-language text)
  "Translate TEXT from SOURCE-LANGUAGE to TARGET-LANGUAGE.

In case of `google-translate-output-destination' is nil pops up a
buffer named *Google Translate* with available translations of
TEXT. In case of `google-translate-output-destination' is
`echo-area' outputs translation in the echo area. If
`google-translate-output-destination' is `popup' outputs
translation in the popup tooltip using `popup' package.

To deal with multi-line regions, sequences of white space
are replaced with a single space. If the region contains not text, a
message is printed."
  (let* ((json (google-translate-request source-language
                                         target-language
                                         text)))
    (if (null json)
        (message "Nothing to translate.")
      (let* ((detailed-translation
              (google-translate-json-detailed-translation json))
             (gtos
              (make-gtos
               :source-language source-language
               :target-language target-language
               :auto-detected-language (aref json 2)
               :text text
               :text-phonetic (google-translate-json-text-phonetic json)
               :translation (google-translate-json-translation json)
               :translation-phonetic (google-translate-json-translation-phonetic json)
               :detailed-translation detailed-translation
               :suggestion (when (null detailed-translation)
                             (google-translate-json-suggestion json)))))
        (cond
         ((null google-translate-output-destination)
          (google-translate-buffer-output-translation gtos))
         ((equal google-translate-output-destination 'echo-area)
          (google-translate-echo-area-output-translation gtos))
         ((equal google-translate-output-destination 'popup)
          (google-translate-popup-output-translation gtos)))))))

(defun google-translate-popup-output-translation (gtos)
  "Output translation to the popup tooltip using `popup'
package."
  (require 'popup)
  (popup-tip
   (with-temp-buffer
     (google-translate-insert-translation gtos)
     (google-translate--trim-string
      (buffer-substring (point-min) (point-max))))))

(defun google-translate-echo-area-output-translation (gtos)
  "Output translation to the echo area (See
http://www.gnu.org/software/emacs/manual/html_node/elisp/The-Echo-Area.html)"
  (message
   (with-temp-buffer
     (google-translate-insert-translation gtos)
     (google-translate--trim-string
      (buffer-substring (point-min) (point-max))))))

(defun google-translate-insert-translation (gtos)
  "Insert translation to the current buffer."
  (let ((translation (gtos-translation gtos))
        (detailed-translation (gtos-detailed-translation gtos)))
    (insert
     (google-translate--translation-title gtos "%s -> %s:")
     (google-translate--translating-text gtos " %s")
     (google-translate--text-phonetic gtos " [%s]")
     " - "
     (google-translate--translated-text gtos "%s")
     (google-translate--translation-phonetic gtos " [%s]")
     (if detailed-translation
         (google-translate--detailed-translation
          detailed-translation translation
          "\n* %s " "%d. %s ")
       (google-translate--suggestion gtos)))))

(defun google-translate-buffer-insert-translation (gtos)
  "Insert translation to the current temp buffer."
  (let ((translation (gtos-translation gtos))
        (detailed-translation (gtos-detailed-translation gtos))
        (inhibit-read-only t))
    (insert
     (google-translate--translation-title gtos "Translate from %s to %s:\n")
     "\n")
    (insert
     (google-translate--translating-text gtos "%s"))
    (when (null google-translate-listen-program)
      (insert "\n"))
    (insert
     (if google-translate-listen-program
         (google-translate--listen-button gtos) "")
     (google-translate--text-phonetic gtos "\n%s\n")
     "\n"
     (google-translate--translated-text gtos "%s\n")
     (google-translate--translation-phonetic gtos "\n%s\n")
     (if detailed-translation
         (google-translate--detailed-translation
          detailed-translation translation
          "\n%s\n" "%2d. %s\n")
       (google-translate--suggestion gtos)))))

(defun google-translate-buffer-output-translation (gtos)
  "Output translation to the temp buffer."
  (let ((buffer-name google-translate-buffer-name))
    (progn
      (with-current-buffer (get-buffer-create buffer-name)
        (let ((inhibit-read-only t)
              (tr-text-pos1 nil)
              (tr-text-pos2 nil))  ;; translating text positions
          (erase-buffer)
          (set-text-properties (point-min) (point-max) nil)
          (google-translate-buffer-insert-translation gtos)

          (put-text-property 1 2 'front-sticky '(read-only))
          (put-text-property (point-min) (point-max) 'read-only t)
          
          (if google-translate-inline-editing
              (progn
                (put-text-property (point-min) (point-max)
                                   'keymap google-translate-inline-text-keymap)
                (google-translate-inline-editing-mode)
                (goto-char (point-min))
                (forward-line 2)
                (setq tr-text-pos1 (- (point) 1))
                (goto-char (line-end-position))
                (setq tr-text-pos2 (+ (point) 1))
                (put-text-property tr-text-pos1 tr-text-pos2 'read-only nil)
                (put-text-property tr-text-pos1 tr-text-pos2 'keymap nil))
            (progn
              (put-text-property (point-min) (point-max)
                                 'keymap google-translate-text-keymap)
              (google-translate-mode)))
          
          (make-local-variable 'gt-source-language)
          (make-local-variable 'gt-target-language)
          (setq gt-source-language (gtos-source-language gtos))
          (setq gt-target-language (gtos-target-language gtos))
          (goto-char (point-min))))
      (pop-to-buffer buffer-name))))

(defun google-translate-read-source-language (&optional prompt)
  "Read a source language, with completion, and return its abbreviation.

The null input is equivalent to \"Detect language\"."
  (let ((completion-ignore-case t)
        (prompt
         (if (null prompt)
             "Translate from: "
           prompt)))
    (google-translate-language-abbreviation
     (google-translate-completing-read
      prompt
      (google-translate-supported-languages)
      "Detect language"))))

(defun google-translate-read-target-language (&optional prompt)
  "Read a target language, with completion, and return its abbreviation.

The input is guaranteed to be non-null."
  (let ((completion-ignore-case t)
        (prompt
         (if (null prompt)
             "Translate to: "
           prompt)))
    (cl-flet ((read-language ()
                             (google-translate-completing-read
                              prompt
                              (google-translate-supported-languages))))
      (let ((target-language (read-language)))
        (while (string-equal target-language "")
          (setq target-language (read-language)))
        (google-translate-language-abbreviation target-language)))))

(defun google-translate-completing-read (prompt choices &optional def)
  "Read a string in the minibuffer with completion.

If `google-translate-enable-ido-completion' is non-NIL, use
ido-style completion."
  (funcall (if google-translate-enable-ido-completion
               #'ido-completing-read
             #'completing-read)
           prompt choices nil t nil nil def))

(define-derived-mode google-translate-mode fundamental-mode "GT"
  "Google Translate major mode. This major mode is mainly
intended to extend fundamental-mode."
  :group 'google-translate)


(provide 'google-translate-core-ui)

;;; google-translate-core-ui.el ends here
