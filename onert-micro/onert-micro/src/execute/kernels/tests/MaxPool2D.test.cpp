/*
 * Copyright (c) 2024 Samsung Electronics Co., Ltd. All Rights Reserved
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "execute/OMTestUtils.h"
#include "test_models/maxpool2d/FloatMaxPool2DKernel.h"
#include "test_models/maxpool2d/NegMaxPool2DKernel.h"

namespace onert_micro
{
namespace execute
{
namespace testing
{

using namespace testing;

class MaxPool2DTest : public ::testing::Test
{
  // Do nothing
};

TEST_F(MaxPool2DTest, Float_P)
{
  onert_micro::test_model::TestDataFloatMaxPool2D test_data_kernel;
  std::vector<float> output_data_vector =
    onert_micro::execute::testing::checkKernel<float>(1, &test_data_kernel);
  EXPECT_THAT(output_data_vector, test_data_kernel.get_output_data_by_index(0));
}

TEST_F(MaxPool2DTest, Input_output_type_mismatch_NEG)
{
  onert_micro::test_model::NegTestDataInputOutputTypeMismatchMaxPool2DKernel test_data_kernel;

  EXPECT_DEATH(checkNEGSISOKernel(&test_data_kernel), "");
}

TEST_F(MaxPool2DTest, Input_invalid_input_type_mismatch_NEG)
{
  onert_micro::test_model::NegTestDataInvalidInputShapeMaxPool2DKernel test_data_kernel;

  EXPECT_DEATH(checkNEGSISOKernel(&test_data_kernel), "");
}

TEST_F(MaxPool2DTest, No_quant_params_mismatch_NEG)
{
  onert_micro::test_model::NegTestDataNoQuantParamsMaxPool2DKernel test_data_kernel;

  EXPECT_DEATH(checkNEGSISOKernel(&test_data_kernel), "");
}

} // namespace testing
} // namespace execute
} // namespace onert_micro
