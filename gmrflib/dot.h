
/* dot.h
 * 
 * Copyright (C) 2022-2024 Havard Rue
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * The author's contact information:
 *
 *        Haavard Rue
 *        CEMSE Division
 *        King Abdullah University of Science and Technology
 *        Thuwal 23955-6900, Saudi Arabia
 *        Email: haavard.rue@kaust.edu.sa
 *        Office: +966 (0)12 808 0640
 *
 *
 */

/*!
  \file utils.h
  \brief Typedefs for \ref utils.c
*/

#ifndef __GMRFLib_DOT_H__
#define __GMRFLib_DOT_H__

#include <stdlib.h>
#include <stddef.h>
#include <math.h>

#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
#define __BEGIN_DECLS extern "C" {
#define __END_DECLS }
#else
#define __BEGIN_DECLS					       /* empty */
#define __END_DECLS					       /* empty */
#endif

__BEGIN_DECLS

#include "GMRFLib/GMRFLibP.h"
double GMRFLib_dsum(int n, double *x);
int GMRFLib_isum(int n, int *ix);
double GMRFLib_ddot(int n, double *x, double *y);
double GMRFLib_ddot_idx(int n, double *v, double *a, int *idx);
double GMRFLib_ddot_idx_mkl(int n, double *v, double *a, int *idx);
double GMRFLib_ddot_idx_mkl_alt(int n, double *v, double *a, int *idx);
double GMRFLib_ddot_idx_mkl_alt(int n, double *v, double *a, int *idx);
double GMRFLib_dot_product(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_group(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_group_mkl(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_group_mkl_alt(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_serial(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_serial_mkl(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dot_product_serial_mkl_alt(GMRFLib_idxval_tp * ELM_, double *ARR_);
double GMRFLib_dsum_idx(int n, double *a, int *idx);
void GMRFLib_dsum_measure_time(double *tused);
void GMRFLib_isum_measure_time(double *tused);
void GMRFLib_chose_threshold_ddot(void);

#define NOT_IN_USE____GMRFLib_dot_product_INLINE(ans_, v_, a_)		\
	if (v_->n >= 8L) {						\
		ans_ = GMRFLib_dot_product(v_, a_);			\
	} else {							\
		double *_v = v_->val;					\
		int *_idx = v_->idx;					\
									\
		switch(v_->n) {						\
		case 0:	ans_ = 0.0; break;				\
		case 1:	ans_ = _v[0] * a_[_idx[0]]; break;		\
		case 2:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]]; break; \
		case 3:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]]; break; \
		case 4:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]]; break; \
		case 5:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]]; break; \
		case 6:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]] + _v[5] * a_[_idx[5]]; break; \
		case 7:	ans_ = _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]] + _v[5] * a_[_idx[5]] + _v[6] * a_[_idx[6]];	\
		}							\
	}

#define NOT_IN_USE____GMRFLib_dot_product_INLINE_ADDTO(ans_, v_, a_)	\
	if (v_->n >= 8L) {						\
		ans_ += GMRFLib_dot_product(v_, a_);			\
	} else {							\
		double *_v = v_->val;					\
		int *_idx = v_->idx;					\
									\
		switch(v_->n) {						\
		case 0:	break;						\
		case 1:	ans_ += _v[0] * a_[_idx[0]]; break;		\
		case 2:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]]; break; \
		case 3:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]]; break; \
		case 4:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]]; break; \
		case 5:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]]; break; \
		case 6:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]] + _v[5] * a_[_idx[5]]; break; \
		case 7:	ans_ += _v[0] * a_[_idx[0]] + _v[1] * a_[_idx[1]] + _v[2] * a_[_idx[2]] + _v[3] * a_[_idx[3]] + _v[4] * a_[_idx[4]] + _v[5] * a_[_idx[5]] + _v[6] * a_[_idx[6]]; \
		}							\
	}


#if defined(INLA_WITH_MKL)
#define GMRFLib_dot_product_INLINE(ans_, v_, a_) ans_ = GMRFLib_dot_product_serial_mkl(v_, a_)
#define GMRFLib_dot_product_INLINE_ADDTO(ans_, v_, a_)	ans_ += GMRFLib_dot_product_serial_mkl(v_, a_)
#else
#define GMRFLib_dot_product_INLINE(ans_, v_, a_) ans_ = GMRFLib_dot_product(v_, a_)
#define GMRFLib_dot_product_INLINE_ADDTO(ans_, v_, a_)	ans_ += GMRFLib_dot_product(v_, a_)
#endif

__END_DECLS
#endif

