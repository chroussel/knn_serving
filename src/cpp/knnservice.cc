#include "knnservice.h"
#include <math.h>
#include <ctime>

knn_result::knn_result(std::vector<std::pair<float, size_t>> items, std::vector<std::pair<std::string, size_t>> metrics)
        : items(std::move(items)), metrics(std::move(metrics)) {}

user_embedding::user_embedding(
        std::vector<float> embedding,
        std::vector<double> weights,
        std::vector<int32_t> indices,
        std::vector<size_t> labels,
        int64_t max_ts,
        int64_t min_ts) :
        embedding(std::move(embedding)),
        weights(std::move(weights)),
        indices(std::move(indices)),
        labels(std::move(labels)),
        max_ts(max_ts),
        min_ts(min_ts) {}

KnnService::KnnService(Distance distance, const int32_t dim, const int32_t ef_search) :
        distance(distance), dim(dim), ef_search(ef_search) {
    data_size = dim * sizeof(float);
}

Index<float> *KnnService::loadIndex(int32_t index_id, const std::string &path_to_index) {
    auto index = new Index<float>(distance, dim);
    index->loadIndex(path_to_index);
    index->appr_alg->setEf(ef_search);
    return index;
}

void KnnService::addIndices(const std::vector<int32_t> &index_ids, const std::vector<Index<float> *> &indices) {
    auto nb_items = index_ids.size();
    for (size_t i = 0; i < nb_items; i++) {
        auto iterator = indices_by_id.find(index_ids[i]);
        if (iterator == indices_by_id.end()) {
            std::unique_ptr<KnnIndex> index {new KnnIndex};
            index->add_index(indices[i]);
            indices_by_id.emplace(index_ids[i], std::move(index));
        } else {
            (iterator->second)->add_index(indices[i]);
        }
    }
}

void KnnService::addExtraItem(int32_t index_id,
                              size_t label,
                              const std::vector<float>& vector) {
    auto iterator = indices_by_id.find(index_id);
    if (iterator == indices_by_id.end()) {
        std::unique_ptr<KnnIndex> index {new KnnIndex};
        index->add_extra_items(label, vector);
        indices_by_id.emplace(index_id, std::move(index));
    } else {
        (iterator->second)->add_extra_items(label, vector);
    }
}

knn_result
KnnService::get_closest_items(
        const UserData &user_data,
        const ModelData &model_data,
        int32_t query_index,
        size_t k
        ) {
    auto start = std::chrono::steady_clock::now();
    std::vector<float> query;

    auto index_pair = indices_by_id.find(query_index);
    if (index_pair == indices_by_id.end() || !index_pair->second->can_query()) {
        return knn_result({}, {});
    }

    auto time_init = std::chrono::steady_clock::now();
    if (model_data.model == TimeDecay) {
        auto user_embedding = compute_weighted_average(user_data, model_data);
        query = user_embedding.embedding;
    } else {
        throw std::runtime_error("Model not supported" + std::to_string(model_data.model));
    }
    auto time_model = std::chrono::steady_clock::now();
    auto time_find_index = std::chrono::steady_clock::now();

    auto result_items = index_pair->second->search(query.data(), k);

    auto end = std::chrono::steady_clock::now();
    auto total_time = end - start;
    std::vector<std::pair<std::string, size_t>> metrics = {
            {"get_closest_items.latency",                    std::chrono::nanoseconds(total_time).count()},
            {"get_closest_items_details.init.latency",       std::chrono::nanoseconds(time_init - start).count()},
            {"get_closest_items_details.model.latency",      std::chrono::nanoseconds(time_model - time_init).count()},
            {"get_closest_items_details.find_index.latency", std::chrono::nanoseconds(time_find_index - time_model).count()},
            {"get_closest_items_details.knn_query.latency",  std::chrono::nanoseconds(end - time_find_index).count()}
    };
    return knn_result(result_items, metrics);
}

const float *KnnService::fetch_item(int index_id, size_t label) {
    auto iter_index = indices_by_id.find(index_id);
    if (iter_index != indices_by_id.end()) {
        return iter_index->second->get_item(label);
    }
    return nullptr;
}

static inline bool is_valid_event(int32_t event_type) {
    return event_type == PRODUCT_VIEW
            || event_type == SALE
            || event_type == BASKET;
}

bool KnnService::has_item(int index_id, size_t label) {
    return fetch_item(index_id, label) != nullptr;
}

std::vector<float> KnnService::normalize(const std::vector<double> &input_vector) {
    double l2norm = 0;
    for (auto &x: input_vector)
        l2norm += x * x;
    if (l2norm <= 0) {
        return std::vector<float>(input_vector.size(), 0);
    }
    l2norm = 1 / sqrt(l2norm);
    std::vector<float> result(input_vector.size());
    std::transform(std::begin(input_vector), std::end(input_vector), std::begin(result), [l2norm](double x) { return (float) (x * l2norm); });
    return result;
}

user_embedding KnnService::compute_weighted_average(
        const UserData &user_data,
        const ModelData &model_data) {
    std::vector<double> user_vector(dim, 0);
    const float *product_vector;

    std::vector<double> weights(0);
    weights.reserve(user_data.nb_items);
    std::vector<int32_t> indices(0);
    indices.reserve(user_data.nb_items);
    std::vector<size_t> labels(0);
    labels.reserve(user_data.nb_items);

    int64_t max_s = 0;
    double weight_sum = 0;

    for (size_t i = 0; i < user_data.nb_items; i++) {
        auto current_timestamp = user_data.timestamps[i];
        if (current_timestamp > max_s
            && is_valid_event(user_data.event_types[i])
            && has_item(user_data.index_ids[i], user_data.query_labels[i])) {
            max_s = current_timestamp;
        }
    }
    auto min_s = max_s - model_data.nb_last_days * SECONDS_IN_DAY;

    for (size_t i = 0; i < user_data.nb_items; i++) {
        auto current_timestamp = user_data.timestamps[i];
        auto current_event = user_data.event_types[i];
        if (!is_valid_event(current_event) || current_timestamp <= min_s) {
            continue;
        }
        auto index_id = user_data.index_ids[i];
        auto label = user_data.query_labels[i];
        product_vector = fetch_item(index_id, label);
        if (product_vector) {
            double weight = exp_decay_weight(max_s - current_timestamp, model_data.half_life);
            weight_sum += weight;
            weights.push_back(weight);
            indices.push_back(index_id);
            labels.push_back(label);
            std::transform(user_vector.begin(), user_vector.end(), product_vector, user_vector.begin(),
                           [weight](float u, float p) { return u + weight * p; });
        }
    }

    if (weight_sum > 0) {
        std::transform(user_vector.begin(), user_vector.end(), user_vector.begin(),
                       std::bind2nd(std::divides<double>(), weight_sum));
    }
    // Removing popularity factor from user embedding to match offline pipeline
    user_vector[user_vector.size() - 1] = 0.0f;
    return user_embedding(KnnService::normalize(user_vector), weights, indices, labels, max_s, min_s);
}

std::vector<int32_t> KnnService::get_indices_ids() {
    std::vector<int32_t> result(indices_by_id.size());
    int32_t *result_data = result.data();
    for (const auto &pair : indices_by_id) {
        *result_data = pair.first;
        result_data++;
    }
    return result;
}

double KnnService::exp_decay_weight(int32_t age_ms, float half_life) {
    double delta_days = age_ms / SECONDS_IN_DAY;
    return 1.0 / pow(2.0, delta_days / half_life);
}