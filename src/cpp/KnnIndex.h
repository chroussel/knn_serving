#ifndef KNN_JNI_KNN_INDEX_H
#define KNN_JNI_KNN_INDEX_H

#include "hnswindex.h"
#include "tsl/robin_map.h"

class KnnIndex {
public:
    std::vector<Index<float> *> index_list;
    tsl::robin_map<size_t, std::vector<float>> extra_items;
    KnnIndex() : index_list({}), extra_items({})
    {

    }

    bool can_query() {
        return !this->index_list.empty();
    }

    virtual ~KnnIndex() {
        for (auto iter : index_list) {
            delete iter;
        }
    }

    size_t extra_item_count() {
        return extra_items.size();
    }

    void add_index(Index<float, float> *const pIndex) {
        index_list.emplace_back(pIndex);
    }

    void add_extra_items(size_t label, const std::vector<float> &vector) {
        this->extra_items.emplace(label, vector);
    }

    const float *get_item(size_t label) {
        auto item_tuple = this->extra_items.find(label);
        if (item_tuple == this->extra_items.end()) {
            for (auto &index: index_list) {
                auto *item = index->getItem(label);
                if (item != nullptr) {
                    return item;
                }
            }
            return nullptr;
        } else {
            return item_tuple->second.data();
        }
    }

    std::vector<std::pair<float, size_t>> search(float *query, size_t k) {
        std::vector<std::pair<float, size_t>> result_items;
        if (index_list.empty()) {
            return result_items;
        }
        std::vector<size_t> tmp_result_items;
        std::vector<float> tmp_result_distances;

        result_items.reserve(k);
        tmp_result_items.reserve(k);
        tmp_result_distances.reserve(k);

        for (auto iter : index_list) {
            auto tmp_result_count = iter->knnQuery(query, tmp_result_items.data(), tmp_result_distances.data(), k);
            for (size_t i = 0; i < tmp_result_count; i++) {
                std::pair<float, size_t> current_pair = {tmp_result_distances[i], tmp_result_items[i]};
                if (result_items.size() < k) {
                    result_items.push_back(current_pair);
                    std::push_heap(std::begin(result_items), std::end(result_items));
                } else {
                    if (result_items[0].first >= current_pair.first) {
                        std::pop_heap(std::begin(result_items), std::end(result_items));
                        result_items.back() = current_pair;
                        std::push_heap(std::begin(result_items), std::end(result_items));
                    }
                }
            }
        }
        return result_items;
    }
};

#endif //KNN_JNI_KNN_INDEX_H
