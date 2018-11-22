#ifndef FIDSERRMISS_FUNCTIONS_H_
#define FIDSERRMISS_FUNCTIONS_H_

//read functions ro data
#define fidsErrMiss_read_ro \
block->setfidsCounters(fasec->read_reg(0));\
block->setpfnMeasOnEvent(fasec->read_reg(4));\
block->setrefCalcPuComp1(fasec->read_reg(8));\
block->setrefCalcPuComp2(fasec->read_reg(12));\
block->setpulseLengthTrigger(fasec->read_reg(16));\
block->setpulseLengthPuComp1(fasec->read_reg(20));\
block->setpulseLengthPuComp2(fasec->read_reg(24));\
block->setdelayTrigComp1(fasec->read_reg(28));\
block->setdelayTrigComp2(fasec->read_reg(32));\
block->setdelayComp1Comp2(fasec->read_reg(36));\
block->setpuName(fasec->read_reg(40));\
block->setrefCalcPuComp1OnEvent(fasec->read_reg(76));\
block->setrefCalcPuComp2OnEvent(fasec->read_reg(80));\

//read functions rw data
#define fidsErrMiss_read_rw \
block->setcalcParamComp1(fasec->read_reg(44));\
block->setcalcParamComp2(fasec->read_reg(48));\
block->setmoduleParam(fasec->read_reg(52));\
block->setwindowLengthMissing(fasec->read_reg(56));\
block->setwindowLengthErratic(fasec->read_reg(60));\
block->setmaxCounterMissing(fasec->read_reg(64));\
block->setmaxCounterErratic(fasec->read_reg(68));\
block->setfallingDebounceLength(fasec->read_reg(72));\

//write functions rw data
#define fidsErrMiss_write_rw \
fasec->write_reg(44,block->getcalcParamComp1());\
fasec->write_reg(48,block->getcalcParamComp2());\
fasec->write_reg(52,block->getmoduleParam());\
fasec->write_reg(56,block->getwindowLengthMissing());\
fasec->write_reg(60,block->getwindowLengthErratic());\
fasec->write_reg(64,block->getmaxCounterMissing());\
fasec->write_reg(68,block->getmaxCounterErratic());\
fasec->write_reg(72,block->getfallingDebounceLength());\

#endif
