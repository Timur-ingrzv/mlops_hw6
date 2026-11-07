workspace "Music application" 

    !identifiers hierarchical

    model {
        u = person "Слушатель" "Слушает музыку и реагирует на нее"
        c = softwareSystem "Клиент Яндекс музыки" "Пользовательский интерфейс сервиса"
        rec = softwareSystem "Сервис рекомендаций" "Выбирает следующий трек для воспроизведения" {
            api = container "Recommendations API" "Принимает запросы на рекомендации и события" "REST"
            ml = container "ML модель рекомендаций" "Генерирует список рекомендаций" "Python, PyTorch" {
                tags "ML"
                validator = component "Request Validator" "Проверяет запрос и берет контекст" "Python"
                feat_builder = component "Feature Builder" "Строит признаковое описание пользователей и треков" "Python"
                cand_gen = component "Candidate Retrieval" "Генерирует список кандидатов" "Python"
                ranker = component "Ranker" "Ранжирует список кандидатов" "Pytorch"
                reranker = component "Reranker" "Переранжирует список треков с учетом бизнес логики: доступность трека, наличие прав" "Python"
                model_resolver = component "Model Resolver" "Загружает опубликованную в продакшн версию модели" "MLFlow client"
                resp_builder = component "Response Builder" "Формирует итоговый ответ ML сервиса" "Python"
            }
            model_registry = container "Хранилище версий" "Хранит версии моделей" "MLFlow" {
                tags "Database"
            }
            feature_store = container "Хранилище признаков" "Хранит признаки пользователей и треков" "Redis" {
                tags "Database"
            }
            
            event_p = container "Процессинг событий" "Обрабатывает события с фидбеком пользователей" "Python, Kafka" {
                tags "Event"
            }
            feat_upd = container "Feature updater" "Обновляет признаки пользователей и треков" "Python, Kafka" {
                tags "Event"
            }
            training_pipeline = container "Training pipeline" "Создает обучающую выборку, обучает и оценивает модель" "Airflow" {
                tags "Event"
            }
        }
        play = softwareSystem "Сервис воспроизведения трека" "Отдает аудиодорожку запрошенного трека"
        catalog = softwareSystem "Каталог треков" "Хранит треки и метаданные о них" {
            tags "Database"
        }

        u -> c "Запрашивает следующий трек и оставляет реакцию"
        c -> rec.api "Запрашивает id трека и отправляет реакцию на него"
        c -> play "Воспроизводит трек"
        rec -> catalog "Проверяет данные трека"
        rec.api -> rec.ml.validator "Запрашивает список рекомендаций"
        rec.ml -> rec.model_registry "Запрашивает текущую версию модели"
        rec.ml -> rec.feature_store "Запрашивает признаки пользователя и треков"
        rec.ml -> catalog "Получает кандидатов и метаданные
        
        rec.ml.validator -> rec.ml.feat_builder "Отдает пользователя и контекст"
        rec.ml.feat_builder -> rec.ml.cand_gen "Отдает признаковое описание пользователя"
        rec.ml.feat_builder -> rec.ml.ranker "Отдает признаковое описание пользователя и треков"
        rec.ml.model_resolver -> rec.ml.cand_gen "Отдает модель генератора кандидатов"
        rec.ml.cand_gen -> rec.ml.ranker "Отдает полученных кандидатов"
        rec.ml.ranker -> rec.ml.reranker "Отдает ранжированный список треков"
        rec.ml.reranker -> rec.ml.resp_builder "Отдает итоговый список треков"
        rec.ml.resp_builder -> rec.api "Возвращает следующий трек пользователя"
        
        rec.ml.model_resolver -> rec.ml.ranker "Отдает модель ранкера"
        rec.ml.model_resolver -> rec.model_registry "Находит prod-версию модели"
        
        
        rec.api -> rec.event_p "Передает событие для обработки"
        rec.event_p -> rec.feat_upd "Обновляет признаки"
        rec.event_p -> rec.training_pipeline "Передает размеченные новые данные"
        
        rec.feat_upd -> rec.feature_store "Обновляет хранимые признаки"
        rec.training_pipeline -> rec.model_registry "Добавляет версию модели"
    }

    views {
        systemContext rec "Context" {
            include u c rec play catalog
            autoLayout lr
        }
        
        container rec "Containers" {
            include *
            autoLayout tb
        }
        
        component rec.ml "Components" {
            include *
            autoLayout lr
        }

       
        
styles {

    element "Element" {
        shape RoundedBox
        background #2563EB
        color #FFFFFF
        stroke #1D4ED8
        strokeWidth 2
        fontSize 22
        width 420
        height 240
    }

    element "Person" {
        shape Person
        background #334155
        color #FFFFFF
        stroke #1E293B
    }

    element "Software System" {
        background #1E3A8A
        color #FFFFFF
        stroke #1E40AF
    }

    element "Container" {
        background #2563EB
        color #FFFFFF
        stroke #1D4ED8
    }

    element "Component" {
        background #7C3AED
        color #FFFFFF
        stroke #6D28D9
        width 400
        height 220
    }

    element "Database" {
        shape Cylinder
        background #475569
        color #FFFFFF
        stroke #334155
    }

    element "ML" {
        background #800080
        color #FFFFFF
        stroke #6D28D9
    }

    element "Event" {
        background #c0c0c0
        color #FFFFFF
        stroke #115E59
    }

    element "Boundary" {
        stroke #94A3B8
        strokeWidth 2
        color #334155
    }

    relationship "Relationship" {
        color #64748B
        thickness 2
        style solid
        routing Direct
        fontSize 18
        width 230
    }
}

    }
}
