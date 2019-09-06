#ifndef KNN_JNI_KNNSERVICEC_H
#define KNN_JNI_KNNSERVICEC_H

#include <cstddef>
#include <cstdint>

extern "C" {
typedef int32_t C_Distance;
typedef int32_t C_Model;

struct knn_result_value {
    size_t item_count;
    const size_t *items;
    const float *distances;
    size_t metric_count;
    const char **metric_names;
    const size_t *metric_values;
};

struct knn_user_input {
    size_t item_count;
    const int32_t *index_ids;
    const size_t *labels;
    const int64_t *timestamps;
    const int32_t *event_types;
};

struct model_input {
    C_Model model;
    int32_t blackout_s;
    float half_life;
    int32_t nb_last_days;
};

typedef void *knn_service_t;
typedef void *knn_index_t;

knn_service_t createKnnService(int32_t distance, int32_t dim, int32_t ef_search);
void destroy(knn_service_t knn);
knn_index_t load_index(knn_service_t knn, int32_t index_id, const char *path);
void addIndices(knn_service_t knn, size_t item_count, const int32_t* index_ids, const knn_index_t* indices);
knn_result_value getClosestItemsAvg(knn_service_t knn, knn_user_input user_input, model_input model_input, int32_t query_index, size_t k);
void addNonSearchableItems(knn_service_t knn, int32_t index_id, size_t label, const float* embedding);
}
#endif //KNN_JNI_KNNSERVICEC_H
