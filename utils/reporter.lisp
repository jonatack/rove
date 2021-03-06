(defpackage #:rove/utils/reporter
  (:use #:cl
        #:rove/core/stats
        #:rove/core/assertion
        #:rove/core/result
        #:rove/misc/stream
        #:rove/misc/color)
  (:export #:format-failure-tests))
(in-package #:rove/utils/reporter)

(defun format-failure-tests (stream context)
  (fresh-line stream)
  (write-char #\Newline stream)
  (let ((stream (make-indent-stream stream)))
    (let ((test-count (context-test-count context)))
      (if (= 0 (length (stats-failed context)))
          (princ
           (color-text :green
                       (format nil "✓ ~D tests completed"
                               (length (stats-passed context))))
           stream)
          (progn
            (princ
             (color-text :red
                         (format nil "× ~D of ~D tests failed"
                                 (length (stats-failed context))
                                 test-count))
             stream)
            (let ((failed-assertions
                    (labels ((assertions (object)
                               (typecase object
                                 (failed-assertion (list object))
                                 (failed-test
                                  (apply #'append
                                         (mapcar #'assertions
                                                 (test-failed-assertions object)))))))
                      (loop for object across (stats-failed context)
                            append (assertions object)))))
              (let ((*print-circle* t)
                    (*print-assertion* t))
                (loop for i from 0
                      for f in failed-assertions
                      do (fresh-line stream)
                         (write-char #\Newline stream)
                         (princ
                          (color-text :white
                                      (format nil "~A) ~A"
                                              i
                                              (if (assertion-labels f)
                                                  (with-output-to-string (s)
                                                    (loop for i from 0
                                                          for (label . rest) on (assertion-labels f)
                                                          do (princ (make-string (* i 2) :initial-element #\Space) s)
                                                             (when (< 0 i)
                                                               (princ "   › " s))
                                                             (princ label s)
                                                             (fresh-line s)))
                                                  (assertion-description f))))
                          stream)
                         (when (assertion-labels f)
                           (with-indent (stream (+ (length (write-to-string i)) 2))
                             (fresh-line stream)
                             (princ
                              (color-text :white
                                          (assertion-description f))
                              stream)))
                         (fresh-line stream)
                         (with-indent (stream (+ (length (write-to-string i)) 2))
                           (when (assertion-reason f)
                             (princ
                              (color-text :red
                                          (format nil "~A: ~A"
                                                  (type-of (assertion-reason f))
                                                  (assertion-reason f)))
                              stream)
                             (fresh-line stream))
                           (with-indent (stream +2)
                             (princ
                              (color-text :gray (princ-to-string f))
                              stream)
                             (fresh-line stream)
                             (when (assertion-stacks f)
                               (write-char #\Newline stream)
                               (loop repeat 15
                                     for stack in (assertion-stacks f)
                                     do (princ (color-text :gray (dissect:present-object stack nil)) stream)
                                        (fresh-line stream))))))))))))
  (fresh-line stream)
  (unless (= 0 (length (stats-pending context)))
    (princ
     (color-text :aqua
                 (format nil "● ~D tests skipped"
                         (length (stats-pending context))))
     stream)
    (fresh-line stream)))
