add_executable(test_deye_models
    test_deye_models.cpp
)

target_link_libraries(test_deye_models PRIVATE
    deye_core
    Qt6::Test
)

add_test(NAME test_deye_models COMMAND test_deye_models)
