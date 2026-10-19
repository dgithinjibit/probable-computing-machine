# Hands_On_Machine_Learning_with_Scikit_Learn_and_TensorFlow_Concepts.pdf
<!-- hand-authored -->

- file: `/home/skware/Desktop/ML/Hands_On_Machine_Learning_with_Scikit_Learn_and_TensorFlow_Concepts.pdf`
- extent: 564 pages (first edition, 2017, O'Reilly)
- registered as: `homl` — **Days 34-38** (Traditional ML, in code)

## Chapter map (Part I and the start of Part II, physical pages)

The detector found the Part I banners but paired them with the exercise lists at the end
of each chapter, which are also numbered lines. The openings below were read off the title
pages. **physical = printed + 22** (chapter 1 is printed 3, physical 25).

| Ch | Title | Printed | Opens (physical) | Used by |
| --- | --- | --- | --- | --- |
| 1 | The Machine Learning Landscape | 3 | 25 | Day 34 |
| 2 | End-to-End Machine Learning Project | 33 | 55 | Day 35 |
| 3 | Classification | 79 | 101 | Day 36 |
| 4 | Training Models | 105 | 127 | Day 37 |
| 5 | Support Vector Machines | 145 | 167 | not yet scheduled |
| 6 | Decision Trees | 167 | 189 | not yet scheduled (Day 26 covers trees from `mlab`) |
| 7 | Ensemble Learning and Random Forests | 181 | 203 | Day 38 |
| 8 | Dimensionality Reduction | 205 | 227 | not yet scheduled |
| 9 | Up and Running with TensorFlow | 229 | 251 | candidate: first TensorFlow day |

Chapters 10 onward in Part II were not located to a page. Use the same method as above -
first page whose top lines carry the chapter title, then add the offset - before scheduling
a day there, because a mid-chapter range reads as a fragment and the exercise lists at each
chapter's end imitate a heading.

## Reading notes

- This is the **first edition**: TensorFlow 1.x graphs and sessions, and the scikit-learn
  APIs it used have moved since. It is the right book for the concepts and the wrong book
  to type code out of.
- Neither scikit-learn, NumPy nor pandas is installed on this laptop and there is no pip, so
  every Géron day pairs with a standard-library exercise in `../../ml-exercises` that does
  the same computation by hand. That is a feature: the confusion matrix, the gradient step
  and the bootstrap average are each about twenty lines once you know what they are.
- A 10-page range here yields 210-330 words of continuous prose. Ranges that start inside a
  chapter return code listings and figure captions instead, which `noise()` strips, so the
  bite collapses to under 180 words - a good tell that the anchor is wrong.
