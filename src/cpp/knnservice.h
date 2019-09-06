#pragma once

#include <utility>
#include <iostream>
#include <vector>
#include <string>
#include <functional>
#include <chrono>
#include "hnswindex.h"
#include "tsl/robin_map.h"
#include "KnnIndex.h"


const float DEFAULT_HALF_LIFE = 7.0;
const int32_t DEFAULT_BLACKOUT_DAYS = 0;
const int32_t SECONDS_IN_DAY = 24 * 60 * 60;

enum Model {
    TimeDecay = 1,
};

// Replica of EventType from Evt Cookie proto schema
// https://codesearch.criteois.com/opengrok/xref/review--vault--soa-idl/proto-applications/engine-recommendation/src/main/protobuf/api/Events.proto
enum EventType {
    MISSING_EVENT_TYPE_FIELD = 0,
    LISTING = 1,
    PRODUCT_VIEW = 2,
    BASKET = 3,
    SALE = 4,
};

struct knn_result {
    std::vector<std::pair<float, size_t>> items;
    std::vector<std::pair<std::string, size_t>> metrics;

    knn_result(std::vector<std::pair<float, size_t>> items, std::vector<std::pair<std::string, size_t>> metrics);
};

struct user_embedding {
    std::vector<float> embedding;
    std::vector<double> weights;
    std::vector<int32_t> indices;
    std::vector<size_t> labels;
    int64_t max_ts;
    int64_t min_ts;

    user_embedding(
            std::vector<float> embedding,
            std::vector<double> weights,
            std::vector<int32_t> indices,
            std::vector<size_t> labels,
            int64_t max_ts,
            int64_t min_ts
    );
};

struct pair_hash {
    size_t operator()(const std::pair<int32_t, size_t> &key) const {
        return std::hash<int32_t>()(key.first) ^ std::hash<size_t>()(key.second);
    }
};

class UserData {
public:
    const size_t nb_items;
    std::vector<int32_t> index_ids;
    std::vector<size_t> query_labels;
    std::vector<int64_t> timestamps;
    std::vector<int32_t> event_types;

    UserData(
            std::vector<int32_t> indexIds,
            std::vector<size_t> queryLabels,
            std::vector<int64_t> timestamps,
            std::vector<int32_t> eventTypes)
            :
            nb_items(indexIds.size()),
            index_ids(std::move(indexIds)),
            query_labels(std::move(queryLabels)),
            timestamps(std::move(timestamps)),
            event_types(std::move(eventTypes)) {}
};

class ModelData {
public:
    const Model model;
    const float half_life;
    const int32_t nb_last_days;

    ModelData(Model model, float halfLife, int32_t nbLastDays)
            :
            model(model),
            half_life(halfLife),
            nb_last_days(nbLastDays) {}
};

class KnnService {
public:
    Distance distance;
    int32_t dim;
    int32_t ef_search;
    size_t data_size;
    std::unordered_map<int32_t, std::unique_ptr<KnnIndex>> indices_by_id;

    KnnService(
            Distance distance,
            int32_t dim,
            int32_t ef_search);

    const float *fetch_item(int index_id, size_t label);

    bool has_item(
            int index_id,
            size_t label);

    Index<float> *loadIndex(
            int index_id,
            const std::string &path_to_index);

    void addIndices(
            const std::vector<int32_t> &index_ids,
            const std::vector<Index<float> *> &indices);

    void addExtraItem(
            int32_t index_id,
            size_t label,
            const std::vector<float>& vector
            );

    knn_result
    get_closest_items(
            const UserData &input,
            const ModelData &model_data,
            int32_t query_index,
            size_t k);

    user_embedding compute_weighted_average(
            const UserData &input,
            const ModelData &model_data);

    std::vector<int32_t> get_indices_ids();

    static double exp_decay_weight(
            int32_t timestamp_s,
            float half_life);

    static std::vector<float> normalize(const std::vector<double> &input_vector);
};
