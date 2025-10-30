/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/


/** fixed point decimal representation. 18 decimal places are kept. */

import { MoveStruct } from '../../../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
const $moduleName = 'suilend::decimal';
export const Decimal = new MoveStruct({ name: `${$moduleName}::Decimal`, fields: {
        value: bcs.u256()
    } });