/**************************************************************
 * THIS FILE IS GENERATED AND SHOULD NOT BE MANUALLY MODIFIED *
 **************************************************************/
import { MoveStruct } from '../../../utils/index.js';
import { bcs } from '@mysten/sui/bcs';
const $moduleName = 'pyth::price_identifier';
export const PriceIdentifier = new MoveStruct({ name: `${$moduleName}::PriceIdentifier`, fields: {
        bytes: bcs.vector(bcs.u8())
    } });